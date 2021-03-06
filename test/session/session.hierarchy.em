describe "Ep.Session", ->

  beforeEach ->
    @App = Ember.Namespace.create()
    @container = new Ember.Container()
    Ep.setupContainer(@container)
    @container.register('adapter:main', Ep.LocalAdapter)

    class @Post extends Ep.Model
      title: Ep.attr('string')
    @App.Post = @Post

    class @Comment extends Ep.Model
      text: Ep.attr('string')
      post: Ep.belongsTo(@Post)
    @App.Comment = @Comment

    @Post.reopen
      comments: Ep.hasMany(@Comment)

    @container.register 'model:post', @Post
    @container.register 'model:comment', @Comment

    @adapter = @container.lookup('adapter:main')
    @container = @adapter.container


  describe 'sibling sessions', ->

    sessionA = null
    sessionB = null
    adapter = null

    beforeEach ->
      sessionA = @adapter.newSession()
      sessionB = @adapter.newSession()

      sessionA.merge @Post.create(id: "1", title: 'original')
      sessionB.merge @Post.create(id: "1", title: 'original')

    it 'updates are isolated', ->
      postA = null
      postB = null

      pA = sessionA.load('post', 1).then (post) ->
        postA = post
        postA.title = "a was here"

      pB = sessionB.load('post', 1).then (post) ->
        postB = post
        postB.title = "b was here"

      Ember.RSVP.all([pA, pB]).then ->
        expect(postA.title).to.eq("a was here")
        expect(postB.title).to.eq("b was here")


  describe "child session", ->

    parent = null
    child = null

    beforeEach ->
      parent = @adapter.newSession()
      child = parent.newSession()

    it '.flushIntoParent flushes updates immediately', ->
      parent.merge @Post.create(id: "1", title: 'original')

      child.load('post', 1).then (childPost) ->

        childPost.title = 'child version'

        parent.load('post', 1).then (parentPost) ->
          expect(parentPost.title).to.eq('original')
          f = child.flushIntoParent()
          expect(parentPost.title).to.eq('child version')
          f

    it '.flush waits for success before updating parent', ->
      parent.merge @Post.create(id: "1", title: 'original')

      child.load('post', 1).then (childPost) ->

        childPost.title = 'child version'

        parent.load('post', 1).then (parentPost) ->
          expect(parentPost.title).to.eq('original')
          f = child.flush()
          expect(parentPost.title).to.eq('original')
          f.then ->
            expect(parentPost.title).to.eq('child version')

    it 'does not mutate parent session relationships', ->
      post = parent.merge @Post.create(id: "1", title: 'parent', comments: [@Comment.create(id: '2', post: Ep.LazyModel.create(type: @Post, id: "1"))])
      expect(post.comments.length).to.eq(1)
      child.add(post)
      expect(post.comments.length).to.eq(1)


    it 'adds hasMany correctly', ->
      parentPost = parent.merge @Post.create(id: "1", title: 'parent', comments: [@Comment.create(id: '2', post: Ep.LazyModel.create(type: @Post, id: "1"))])
      post = child.add(parentPost)
      expect(post).to.not.eq(parentPost)
      expect(post.comments.length).to.eq(1)
      expect(post.comments.firstObject).to.not.eq(parentPost.firstObject)
