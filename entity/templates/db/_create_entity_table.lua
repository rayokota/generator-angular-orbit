local luasql = require "luasql.sqlite3"
local env = luasql.sqlite3()
local conn = env:connect("my.db")
conn:execute("CREATE TABLE <%= pluralize(name) %> (<% _.each(attrs, function (attr) { %><%= attr.attrName %> <% if (attr.attrType == 'Enum' || attr.attrType == 'Date') { %>STRING, <% } else { %><%= attr.attrType.toUpperCase() %>, <% }}); %>id INTEGER PRIMARY KEY)")
conn:close()
env:close()
