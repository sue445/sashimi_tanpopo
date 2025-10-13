# Recipe file specification
Recipe file is simple Ruby script, with some exceptions.

By avoiding the DSL variables and methods listed below, you are free to write code as you like.

## Special variables available within recipe file
The following variables are special variables available within recipe file.

### `params`
Passed from `--params`

e.g.

```bash
sashimi_tanpopo local --params name:sue445 --params lang:ja recipe.rb
```

within `recipe.rb`

```rb
# recipe.rb

params
#=> {name: "sue445", lang: "ja"}
```

### Special functions available within recipe file
The following functions are special variables available within recipe file.

## `update_file`
Update files if exists

```ruby
# Update single file
update_file "test.txt" do |content|
  content.gsub!("name", params[:name])
end

# Update multiple files
update_file ".github/workflows/*.yml" do |content|
  content.gsub!(/ruby-version: "(.+)"/, %Q{ruby-version: "#{params[:ruby_version]}"})
end
```

Parameters:

* `pattern`: Path to target file. This supports [`Dir.glob`](https://ruby-doc.org/current/Dir.html#method-c-glob) pattern. e.g. `.github/workflows/*.yml`

Yield Parameters:

* `content`: Content of file. If `content` is changed in block, file will be changed.
