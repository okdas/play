module.exports= class ServerStoreTag
    @table= 'server_tag'
    @tableTag= 'tag'
    @tableTagTags= 'tag_tags'

    constructor: (data) ->
        @id= data.id

        @name= data.name

        @titleRuPlural= data.titleRuPlural
        @titleRuSingular= data.titleRuSingular
        @titleEnPlural= data.titleEnPlural
        @titleEnSingular= data.titleEnSingular

        @tags= []

    @query: (serverId, maria, done) ->
        tags= null

        maria.query "
            SELECT

                Tag.id,

                Tag.name,

                Tag.titleRuPlural,
                Tag.titleRuSingular,

                Tag.titleEnPlural,
                Tag.titleEnSingular

            FROM
                ?? as ServerTag
            JOIN
                ?? as Tag
                ON Tag.id= ServerTag.tagId

            WHERE
                ServerTag.serverId = ?
            "
        ,   [@table, @tableTag, serverId]
        ,   (err, rows) =>

                if not err
                    tags= []
                    for row in rows
                        tags.push new @ row

                done err, tags

    @queryByTags: (tags, maria, done) ->

        idx= {}
        ids= []
        for tag in tags
            idx[tag.id]= tag

        ids= Object.keys idx

        if not ids.length
            return do done

        maria.query "
            SELECT

                Tag.id,

                Tag.name,

                Tag.titleRuPlural,
                Tag.titleRuSingular,

                Tag.titleEnPlural,
                Tag.titleEnSingular,

                GROUP_CONCAT(TagTags.tagId) as tags

              FROM
                ?? as TagTags
              JOIN
                ?? as Tag
                ON Tag.id= TagTags.childId

             WHERE
                TagTags.tagId IN(?)

             GROUP BY
                Tag.id

            "
        ,   [@tableTagTags, @tableTag, ids]
        ,   (err, rows) =>

                done err, rows
