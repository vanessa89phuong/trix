#= require trix/utilities/object
#= require trix/utilities/hash
#= require trix/models/piece
#= require trix/models/splittable_list

class Trix.Text extends Trix.Object
  @textForAttachmentWithAttributes: (attachment, attributes) ->
    piece = Trix.Piece.forAttachment(attachment, attributes)
    new this [piece]

  @textForStringWithAttributes: (string, attributes) ->
    piece = new Trix.Piece string, attributes
    new this [piece]

  @fromJSON: (textJSON) ->
    pieces = for pieceJSON in textJSON
      Trix.Piece.fromJSON pieceJSON
    new this pieces

  constructor: (pieces = []) ->
    super
    @pieceList = new Trix.SplittableList pieces

  copy: ->
    @copyWithPieceList @pieceList

  copyWithPieceList: (pieceList) ->
    new @constructor pieceList.consolidate().toArray(), @attributes

  appendText: (text) ->
    @insertTextAtPosition(text, @getLength())

  insertTextAtPosition: (text, position) ->
    @copyWithPieceList @pieceList.insertSplittableListAtPosition(text.pieceList, position)

  removeTextAtRange: (range) ->
    @copyWithPieceList @pieceList.removeObjectsInRange(range)

  replaceTextAtRange: (text, range) ->
    @removeTextAtRange(range).insertTextAtPosition(text, range[0])

  moveTextFromRangeToPosition: (range, position) ->
    return if range[0] <= position <= range[1]
    text = @getTextAtRange(range)
    length = text.getLength()
    position -= length if range[0] < position
    @removeTextAtRange(range).insertTextAtPosition(text, position)

  addAttributeAtRange: (attribute, value, range) ->
    attributes = {}
    attributes[attribute] = value
    @addAttributesAtRange(attributes, range)

  addAttributesAtRange: (attributes, range) ->
    @copyWithPieceList @pieceList.transformObjectsInRange range, (piece) ->
      piece.copyWithAdditionalAttributes(attributes)

  removeAttributeAtRange: (attribute, range) ->
    @copyWithPieceList @pieceList.transformObjectsInRange range, (piece) ->
      piece.copyWithoutAttribute(attribute)

  setAttributesAtRange: (attributes, range) ->
    @copyWithPieceList @pieceList.transformObjectsInRange range, (piece) ->
      piece.copyWithAttributes(attributes)

  getAttributesAtPosition: (position) ->
    @pieceList.getObjectAtPosition(position)?.getAttributes() ? {}

  getCommonAttributes: ->
    objects = (piece.getAttributes() for piece in @pieceList.toArray())
    Trix.Hash.fromCommonAttributesOfObjects(objects).toObject()

  getCommonAttributesAtRange: (range) ->
    @getTextAtRange(range).getCommonAttributes() ? {}

  getTextAtRange: (range) ->
    @copyWithPieceList @pieceList.getSplittableListInRange(range)

  getStringAtRange: (range) ->
    @pieceList.getSplittableListInRange(range).toString()

  getAttachments: ->
    piece.attachment for piece in @pieceList.toArray() when piece.attachment?

  getAttachmentAndPositionById: (attachmentId) ->
    position = 0
    for piece in @pieceList.toArray()
      if piece.attachment?.id is attachmentId
        return { attachment: piece.attachment, position }
      position += piece.length
    attachment: null, position: null

  getAttachmentById: (attachmentId) ->
    {attachment, position} = @getAttachmentAndPositionById(attachmentId)
    attachment

  getRangeOfAttachment: (attachment) ->
    {attachment, position} = @getAttachmentAndPositionById(attachment.id)
    [position, position + 1] if attachment?

  resizeAttachmentToDimensions: (attachment, {width, height} = {}) ->
    if range = @getRangeOfAttachment(attachment)
      @addAttributesAtRange({width, height}, range)
    else
      this

  getLength: ->
    @pieceList.getLength()

  isEqualTo: (text) ->
    super or text?.pieceList?.isEqualTo(@pieceList)

  eachRun: (callback) ->
    position = 0
    @pieceList.eachObject (piece) ->
      id = piece.id
      attributes = piece.getAttributes()
      run = {id, attributes, position}

      if piece.attachment
        run.attachment = piece.attachment
      else
        run.string = piece.toString()

      callback(run)
      position += piece.length

  contentsForInspection: ->
    pieceList: @pieceList.inspect()

  toString: ->
    @pieceList.toString()

  toJSON: ->
    @pieceList.toJSON()
