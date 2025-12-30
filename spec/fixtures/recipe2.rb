update_file "test.txt" do |content|
  content.gsub!("Hi", "Hello")
end
