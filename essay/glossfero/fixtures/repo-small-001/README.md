# yarncrawler-mini

Fixture repository for Glossfero conformance testing. A deliberately tiny
system with two subsystems that have different co-change signatures:
`core`/`schema` change together frequently; `parser` changes independently
and depends on `core` without `core` depending back.
