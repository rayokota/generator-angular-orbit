#!/usr/bin/env wsapi.cgi

local orbit = require "orbit"
orbit.cache = require "orbit.cache"
local luasql = require "luasql.sqlite3"

local json = require "json"
local encode = json.encode
local decode = json.decode

local app = orbit.new()
app.mapper.conn = luasql.sqlite3():connect(app.real_path .. "/my.db")
<% _.each(entities, function (entity) { %>
local <%= entity.name %>_list = app:model("<%= pluralize(entity.name) %>")<% }); %>
local cache = orbit.cache.new(app)

function table.remove_id(t)
  local t2 = {}
  for k,v in pairs(t) do
    if k ~= "id" then t2[k] = v end
  end
  return t2
end

function app.index(web)
  return app:serve_static(web, app.real_path .. "/index.html")
end

app:dispatch_get(app.index, "/")

<% _.each(entities, function (entity) { %>
function <%= entity.name %>_list:url()
  return "/<%= baseName %>/<%= pluralize(entity.name) %>/" .. self.id
end

function <%= entity.name %>_list:to_json()
  return { <% _.each(entity.attrs, function (attr) { %><%= attr.attrName %> = self.<%= attr.attrName %>, <% }); %>id = self.id }
end

function app.get_<%= pluralize(entity.name) %>(web)
  web:content_type("application/json")
  local <%= pluralize(entity.name) %>, json = <%= entity.name %>_list:find_all{ order = "id asc" }, {}
  for i, <%= entity.name %> in ipairs(<%= pluralize(entity.name) %>) do json[i] = <%= entity.name %>:to_json() end
  return encode(json)
end

app:dispatch_get(cache(app.get_<%= pluralize(entity.name) %>), "/<%= baseName %>/<%= pluralize(entity.name) %>")

function app.add_<%= entity.name %>(web)
  local opt = decode(web.input.post_data)
  local <%= entity.name %> = <%= entity.name %>_list:new(table.remove_id(opt))
  <%= entity.name %>:save()
  web.headers["Location"] = <%= entity.name %>:url()
  web.status = "201 Created"
  web:content_type("application/json")
  cache:invalidate("/<%= baseName %>/<%= pluralize(entity.name) %>")
  return encode(<%= entity.name %>:to_json())
end

app:dispatch_post(app.add_<%= entity.name %>, "/<%= baseName %>/<%= pluralize(entity.name) %>")

function app.get_<%= entity.name %>(web, id)
  local <%= entity.name %> = <%= entity.name %>_list:find(tonumber(id))
  if not <%= entity.name %> then return app.not_found(web) end
  web:content_type("application/json")
  return encode(<%= entity.name %>:to_json())
end

app:dispatch_get(cache(app.get_<%= entity.name %>), "/<%= baseName %>/<%= pluralize(entity.name) %>/(%d+)")

function app.put_<%= entity.name %>(web, id)
  local <%= entity.name %> = <%= entity.name %>_list:find(tonumber(id))
  if not <%= entity.name %> then return app.not_found(web) end
  local opt = decode(web.input.post_data)
  <% _.each(entity.attrs, function (attr) { %>
  <%= entity.name %>.<%= attr.attrName %> = opt.<%= attr.attrName %><% }); %>
  <%= entity.name %>:save()
  cache:invalidate(<%= entity.name %>:url())
  cache:invalidate("/<%= baseName %>/<%= pluralize(entity.name) %>")
  web:content_type("application/json")
  return encode(<%= entity.name %>:to_json())
end

app:dispatch_put(app.put_<%= entity.name %>, "/<%= baseName %>/<%= pluralize(entity.name) %>/(%d+)")

function app.delete_<%= entity.name %>(web, id)
  local <%= entity.name %> = <%= entity.name %>_list:find(tonumber(id))
  if not <%= entity.name %> then return app.not_found(web) end
  <%= entity.name %>:delete()
  web.status = "204"
  cache:invalidate("/<%= baseName %>/<%= pluralize(entity.name) %>")
end

app:dispatch_delete(app.delete_<%= entity.name %>, "/<%= baseName %>/<%= pluralize(entity.name) %>/(%d+)")
<% }); %>

app:dispatch_static("/css/.*")
app:dispatch_static("/js/.*")
app:dispatch_static("/lib/.*")
app:dispatch_static("/views/.*")

return app
