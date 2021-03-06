{basename} = require './helpers'
_ = require 'underscore-plus'
module.exports = class Entry

  constructor: (@name)->
    @children = []

    @type =null
    @fileName = null
    @fileLine = -1
    @fileColumn = -1
    @isPublic = false

    @expanded = true

    @parent = null


  getNameAsParent: ->
    return @name

  getIdentifier: ->
    parentName = @parent?.getNameAsParent()
    if parentName?
      parentName = " (" + parentName + ")"
    else
      parentName = ""

    return @name + parentName


  getTitle: ->
    if @fileName? and @fileLine?
      basename(@fileName)+":"+@fileLine
    else
      @name

  updateChild: (child) ->

    # if entry has a receiver
    if child?.Receiver?
      @getOrCreateChild(child.Receiver).getOrCreateChild(child.Name).updateEntry(child)
    else
      @getOrCreateChild(child.Name).updateEntry(child)

  getOrCreateChild: (name) ->
    child = @getChild(name)
    if !child?
      child = @addChild(name, new Entry(name))

    return child

  sorter:(children) ->
    sortedChildren = children.slice(0)

    sortedChildren.sort((l,r) ->
      typeDiff = l.getTypeRank() - r.getTypeRank()
      if typeDiff isnt 0
        return typeDiff

      return l.name.localeCompare(r.name)
    )

    return sortedChildren

  sortChildren: ->
    @children = @sorter(@children)

    _.each(@children, (c) -> c.sortChildren(true))


  # returns all children recursively.
  getChildrenFlat: ->
    flatChildren = _.flatten([@children, _.map(@children, (c) -> c.getChildrenFlat())])
    return @sorter(flatChildren)

  hasChild: (name) ->
    return _.some(@children, (child) => child.name is name)

  getChild: (name) ->
    return _.find(@children, (child) => child.name is name)

  addChild: (name, child) ->
    @children.push child
    child.parent = @

    return child

  removeChild: (name) ->
    @children = _.filter(@children, (c) -> c.name isnt name)

  expandAll: (expanded) ->
    @expanded = expanded
    _.each(@children, (c) -> c.expandAll(expanded))

  updateEntry: (data)->
    if data.Name?
      @name = data.Name
    if data.FileName?
      @fileName = data.FileName
    if data.Line?
      @fileLine = data.Line
    if data.Column?
      @fileColumn = data.Column
    if data.Public?
      @isPublic = data.Public
    if data.Elemtype?
      @type = data.Elemtype

  getTypeRank: ->
    switch @type
      when "variable" then 0
      when "type" then 1
      when "func" then 2

  removeRemainingChildren: (fileName, existingChildNames) ->
    i=0
    while i < @children.length
      child = @children[i]
      r = child.removeRemainingChildren(fileName, existingChildNames)

      # child is of the file, the child's name is not in the new list and it does not have any children itself
      # so we'll remove it.
      if child.fileName == fileName and !(child.name in existingChildNames)
        @removeChild(child.name)
        continue
      i+= 1
