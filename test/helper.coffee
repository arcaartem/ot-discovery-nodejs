chai = require "chai"
{expect} = chai
sinon = require "sinon"
sinonChai = require 'sinon-chai'

chai.use sinonChai

replaceMethod = (obj, method, fn) ->
  expect(obj).to.respondTo method
  fn ?= sinon.spy()
  obj[method] = fn

module.exports =
  replaceMethod: replaceMethod
