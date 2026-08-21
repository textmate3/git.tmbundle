# Notes from test suite modernization (2026-08-20)

Findings from modernizing this bundle's test suites.

This was a genuine port, not a cleanup. The suites were written for RSpec 1 with `hpricot` for HTML assertions.

## Result

From the bundle root:

```sh
bundle install
bundle exec rspec Support/spec Support/tmvc/spec    # 177 examples, 0 failures
```

Two suites: `Support/tmvc/spec` covers the bundle's miniature model view controller framework (tag and HTML helpers, Hash and String extensions), and `Support/spec` covers the eleven controllers and the git command wrappers, driven by a hand-rolled `Git` command mock and real fixture transcripts in `Support/spec/fixtures/`.

## The port

- **RSpec 1 to modern RSpec.** The `should` expectation syntax and `should_receive`/`stub` mock syntax still exist behind configuration (`syntax = [:should, :expect]` for both `rspec-expectations` and `rspec-mocks`), which kept roughly 400 call sites untouched. The genuinely removed forms were swept: `stub!` to `stub`, bare `stub("name")`/`mock("name")` `doubles` to `double("name")`, `describe ..., :shared => true` to `shared_examples`, empty `with()` to `with(no_args)`, `any_number_of_times` to `stub`, and the `have(n).things` matcher now comes from the rspec-collection_matchers gem. RSpec 1 also auto-included a described `Module` into its example group, so `describe HtmlHelpers` blocks needed explicit `include` lines. The `run_all_spec.rb` glob runner and `spec.opts` were deleted in favor of `rspec` itself and `.rspec`.
- **hpricot to nokogiri.** `Nokogiri` keeps the `doc / "selector"` search operator, so most assertion code survived. Differences that needed touching: `Nokogiri::HTML(...)` construction, `element["attr"]` instead of `element.attributes["attr"]`, and CSS selectors instead of `hpricot`'s XPath-flavored strings (`select[name='rev'] option`).
- **Ruby 3 keyword argument separation reaches into mocks.** `should_receive(:diff).with(:path => ".")` is matched as keyword arguments while the code under test passes an options hash. Explicit braces (`with({...})`) restore the intent.

## Bugs the suites caught in live bundle code

- **`log_controller.rb` still required Bundle Support's deleted `osx/plist` C extension.** The require was vestigial (nothing in this bundle ever called `OSX::PropertyList`), but it made every log controller load raise. This is the kind of leftover the Ruby modernization's syntax sweeps could not see.
- **`application_controller.rb` used the four-positional-argument `ERB.new`**, removed in Ruby 3.0, so every template render raised. One line, 57 failing examples.
- **`SELF_CLOSABLE_TAGS` was missing `input`**, so `button_tag` emitted `<input ...></input>` while its spec documents the self-closing void element form.

## Cross-bundle knock-on

`Bundle Support`'s vendored `CFPropertyList` requires `kconv` and `base64`, which left Ruby's default gems in 3.4. Under plain `ruby` they resolve from installed gems, but under bundler they must be declared, hence `nkf` and `base64` in this bundle's `Gemfile`. Any other bundle that loads the plist shim under bundler will need the same, and the cleaner long-term fix belongs in `bundle-support` (upgrade or patch the vendored `CFPropertyList`).

## Observations, left unchanged

- Three spec expectations documented behavior the code never had. An `Array` return from `javascript_include_tag`, an unescaped ampersand in an `href`. They were corrected to match the code's sensible behavior rather than the reverse.
- The suites use the deprecated `should` syntax throughout. A sweep to `expect` is cosmetic and separate.
- `spec_helpers.rb` still monkey-patches `Object::STDOUT` for output capture and stubs the `Git` class via class variables, both live and exercised.
