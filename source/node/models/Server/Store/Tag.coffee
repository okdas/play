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

        @tags= data.tags

    @query: (serverId, maria, done) ->
        tags= null

        maria.query "
            SELECT

                Tag.id,

                Tag.name,

                Tag.titleRuPlural,
                Tag.titleRuSingular,

                Tag.titleEnPlural,
                Tag.titleEnSingular,

                GROUP_CONCAT(TagTags.childId) as tags

              FROM
                ?? as ServerTag
              JOIN
                ?? as Tag
                ON Tag.id= ServerTag.tagId
              LEFT OUTER JOIN
                ?? as TagTags
                ON TagTags.tagId = Tag.id

             WHERE
                ServerTag.serverId = ?

             GROUP BY
                Tag.id
            "
        ,   [@table, @tableTag, @tableTagTags, serverId]
        ,   (err, rows) =>

                if not err
                    tags= []
                    for row in rows
                        tags.push new @ row

                done err, tags
