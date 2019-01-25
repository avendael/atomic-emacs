Utils = require '../lib/utils'

describe 'Utils', ->
  describe '.escapeForRegExp', ->
    it "escapes regexp metacharacters", ->
      result = Utils.escapeForRegExp('-/\\^$*+?.()|[]{}')
      expect(result).toEqual('\\-\\/\\\\\\^\\$\\*\\+\\?\\.\\(\\)\\|\\[\\]\\{\\}')
