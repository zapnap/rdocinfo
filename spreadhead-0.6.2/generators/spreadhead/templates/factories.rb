Factory.sequence :page_title do |n|
  "Mr. Smith's #{n}th Request"
end

Factory.define :page do |page|
  page.title                 { Factory.next :page_title }
  page.text                  { "Paging Mrs. Smith" }
  page.description           { "What Mr. Smith Says" }
  page.keywords              { "smith paging" }
  page.formatting            { "plain" }
  page.published             { true }
end