module.exports= class Pex
    @table: 'pex'

    @tableEntity: 'pex_entity'
    @tableInheritance: 'pex_inheritance'

    @getByPlayerName: (playerName, maria, done) ->
        maria.query "
            SELECT
                PexEntity.name,
                PexEntity.prefix,
                PexEntity.suffix,
                GROUP_CONCAT(PexInheritance.parent) as groups
              FROM
                ?? as PexEntity
              LEFT OUTER JOIN
                ?? as PexInheritance
                ON PexEntity.name = PexInheritance.child AND PexInheritance.type = 1
             WHERE
                PexEntity.type = 1
               AND
                PexEntity.name = ?
             GROUP
                BY
                PexEntity.name
            "
        ,   [@tableEntity, @tableInheritance, playerName]
        ,   (err, rows) =>
                pex= null

                if not err
                    pex= rows[0]

                done err, pex
