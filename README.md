Playing around here, nothing set in stone.

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

