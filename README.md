Playing around here, nothing set in stone.

## Goal:

To allow more languages to be "documented" on CodeTriage

## Assumptions:

You will need to install a language to generate docs for that lang.

## Concerns:

I want the core web app to be semi-easy-ish to maintain. This means we cannot require installation of X number of languages as a requirement for simply keeping it bootable.

# Approach:

## Boot a language

Each language would get it's own app. It would Run Ruby and whatever the other buildpack required to generate docs is, such as Crystal. This also buys us horizontal scale as we can potentially scale up or down a language based on it's usage.

## Write docs

To do this I want to define an interface where each language can have a script. We pass that script the location to a directory with a project already cloned, that script then generates docs and writes them to an intermediary file. I'm currently thinking newline seperated json blobs. I've got an example in the `JSON doc entry` below

## Save docs

Once that file is written, we can find some way to import the results back into the main CodeTriage database.

This is more an implementation "detail", I've thought of a few ways we can send the docs back to the main app.

- Write directly to the DB via shared DB credentials
  - Pros:
    - Rolling DB credentials happens automatically via attached addons
    - Most direct method of recording docs, as it eventually has to make it into the database
  - Cons:
    - Shared DB connection is major coupling. Consumes a DB connection (not free)

- Write to a shared redis (sidekiq) queue
  - Pros:
    - Rolling Redis credentials happens automatically via attached addons
    - Slight seperation of concerns compared to writing to the DB
  - Cons:
    - Increased worker load, still have to unpack and write to the database once dequeued
    - Shared reddis connection is major coupling. Consumes a redis connection (not free)

- Post back to the app via an API
  - Pros:
    - Clean seperation of concerns, the language apps don't need to share any connections
  - Cons:
    - Have to home-bake security, manually roll some kind of a secret token
    - Lots of extra load on the main website


I'll also mention we need to think about how we want to notify each language doc app about what docs need to be written. I.e. our main app might know that `rails/rails` needs new docs, but our doc app needs to know that.

Whatever we do to save the docs makes this step easier or harder. For example. If we have our doc app connect and query the database directly then it is pretty easy to also save the docs via a database. Same goes for redis, and the API method, we would already have to maintain a secret token system.

## Writing a Doc Parser

CodeTriage supports sending people documented and undocumented methods. It has native support for Ruby, because thats what [@schneems](https://www.twitter.com/schneems) writes in. However there is an API for getting your favorite "language" supported.

## Architecture

We must be able to parse docs for your language, most likely this means we need to run your language in production.

### Running your Language in Production

Your lang needs to be able to run on Heroku. Each doc parser will run in it's own app that will install Ruby and whatever code you need to parse documentation.

To get started look at the [Ruby doc app]().


### Doc Communication

Once you've parsed that documentation we need to get it back into the CodeTriage database. We use redis and `sidekiq` as a transport medium. Each redis entry represents a single documentation entry. Your language does not need to be able to enqueue into redis, instead you can write to a file on disk and our utilities can enqueue into redis for you.


## Executing Doc Parsers

### Executable interface

You need to provide a script that will be called once for each library that needs to be documented. Our tools will clone the project and execute your `bin/document` command that you need to provide:

```
$ bin/document --repo_path="<location/to/project/folder>" --output_file="<location/to/output/file.docs>"
```

The option `repo_path` will be the location of the folder where the project has been downloaded. The second option `output_file` is the location of the file that CodeTriage expects your docs to be written to. Other arguments or options may be added at a later time.

## Output File format

We expect a newline seperated file with each line being a json blob that represents a single documentation entry.

```
$ cat <location/to/output/file.docs>
{ name: "foo" }
{ name: "foo" }
```

Note: that the whole file is not valid json, but each individual line should be json. This is done to make streaming results back to the parent app easier (so we only have to parse individual lines, not the whole thing).

## JSON doc entry

Here is expected interface for json in the file.

```ruby
{
  name: "pipetree",                  # String: Name of method
  full_name: "DSL::Import#pipetree", # String: The full name of the method, i.e. how would you call it from a root context
  line: 199,                         # Numeric: The line number where the docs (or thing to be documented) is located
  path: "lib/foo/import.rb",         # String: The full path to the file of the thing that is being documented
  comment: "I ama comment",          # String: Contents of the documentation, can be null or the key ommitted when docs not present
  language:   "Ruby",                # String: The language of the parser, Must match Repo::CLASS_FOR_DOC_LANGUAGE list
  skip_write: false,                 # Boolean: When true, we will not email to someone who want's to "write docs"
  skip_read:  false,                 # Boolean: When true, we will not email to someone who want's to "read docs"
}
```

We will add

- commit_sha
- github_full_name

