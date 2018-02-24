--# coordinate system manipulation

--http://www.spatialreference.org
--SRID is a Spatial Reference system IDentifier

SELECT ST_SRID(geom) FROM states2;                     -- what is current projection ('geom' field)
                                                       -- ...'0' means 'don't know' (where in space)

--

SELECT UpdateGeometrySRID('states2','geom',2796)       -- define a projection (the ref system)
                                                       -- ...doesn't transform the actual geometry
                                                       -- (layer name, field name, new SRID)

--

SELECT ST_Transform(geom,3450) FROM states2;           -- change projection (but not perm in table)

--

SELECT name, ST_Transform(geom,3450) AS geometry INTO states3  -- change table to see in QGIS layer
FROM states2;

--

ALTER TABLE states2                   -- change existing table/layer, not create new (cf. 'states3')
	ALTER COLUMN geom
	TYPE Geometry(Multipolygon,2959)
	USING ST_Transform(geom,2959);    -- convert 'geom' col (to value '2959')



--# Spatial operations. (Adjacent, Buffer, Contains, Distance, Intersect, more...)

--http://postgis.net/docs/manual-1.3/ch06.html
--http://postgis.org/docs/reference.html

--Adjacent :

SELECT * FROM parcels
WHERE st_touches(parcels.geometry,
	(SELECT geometry
	FROM parcels
	WHERE parcelkey = '50070006200000010150000000')     -- Parcels touching specific one. (9 rows)
	)

--

DROP TABLE qlayer

SELECT * INTO qlayer FROM parcels
WHERE st_touches(parcels.geometry,
	(SELECT geometry
	FROM parcels
	WHERE parcelkey = '50070006200000010150000000')
	)

--

SELECT sum(asmt)::numeric::money AS sumasmt, sum(land)::numeric::money AS sumland
FROM parcels
WHERE st_touches(parcels.geometry,
	(SELECT geometry
	FROM parcels
	WHERE parcelkey = '50070006200000010150000000')    -- get value of adjacent assessments/land
	)

--

SELECT addrno || ' ' || addrstreet AS address
FROM parcels
WHERE st_touches(parcels.geometry,
	(SELECT geometry
	FROM parcels
	WHERE parcelkey = '50070006200000010150000000')    -- addresses of adjacent parcels
	)
--|| represents string concatenation. Unfortunately, not portable across all sql dialects
--https://stackoverflow.com/questions/23372550/what-does-sql-select-symbol-mean
	
--

SELECT addrno || ' ' || addrstreet AS address
FROM parcels
WHERE st_touches(parcels.geometry,
	(SELECT geometry
	FROM parcels
	WHERE parcelkey = '50070006200000010150000000')
	)
AND asmt > 210000                                      -- 'find rich neighbours' (5 rows)

--Buffer :

DROP TABLE qlayer;

SELECT parcels.parcel_id, st_buffer(geometry,100) AS geometry
INTO qlayer
FROM parcels
WHERE parcelkey = '50070000900000040130000000'

--Contains :

DROP TABLE qlayer;

SELECT parcels.*
INTO qlayer
FROM parcels,firm
WHERE st_contains(firm.geometry,parcels.geometry)
AND firm.zone = 'AE'                           -- parcel is fully-contained inside flood zone 'AE' 
                                               -- ...107 rows

--

DROP TABLE qlayer;

SELECT parcels.*
INTO qlayer
FROM parcels,firm
WHERE st_intersects(firm.geometry,parcels.geometry) -- cf. 'Contains' [to help understanding that]
AND firm.zone = 'AE'                                -- parcel fully or partly in flood zone 'AE' 
                                                    -- ...320 rows

--



