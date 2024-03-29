PGDMP  /                     |            ikbs    16.0    16.0 ~   �            0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            �            0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            �            0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            �            1262    16399    ikbs    DATABASE        CREATE DATABASE ikbs WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'English_United States.1252';
    DROP DATABASE ikbs;
                iis    false                        2615    21772    iis    SCHEMA        CREATE SCHEMA iis;
    DROP SCHEMA iis;
                iis    false            �           1255    21773    bmv_rec(numeric)    FUNCTION       CREATE FUNCTION iis.bmv_rec(uparent numeric) RETURNS TABLE(result_id numeric, result_parentid numeric, result_code text, result_text text, result_tp numeric, result_brojac numeric)
    LANGUAGE plpgsql
    AS $$
DECLARE
begin
  IF uParent = 0 THEN
    -- Resetujemo sekvencu samo ako je uParent jednak nuli
    BEGIN
      EXECUTE 'DROP SEQUENCE bmv_seq';
    EXCEPTION
      WHEN OTHERS THEN
        -- Ako greška bude "sequence does not exist," ignorisaćemo je
        IF SQLSTATE = '42704' THEN
          RAISE NOTICE 'Sequence bmv_seq does not exist, continuing...';
        ELSE
          -- Ako je drugačija greška, ponovo podižemo izuzetak
          RAISE;
        END IF;
    END;
    CREATE TEMP SEQUENCE bmv_seq;
  END IF;	
  FOR result_id, result_parentid, result_code, result_text, result_tp IN (
    SELECT id, parentid, code, text, tp
    FROM bmv
    WHERE parentid IS null
    and uParent = 0

    UNION ALL

    SELECT b.id, b.parentid, b.code, b.text, b.tp
    FROM bmv b
    WHERE b.parentid = uParent
    and uParent > 0
  )
  loop
    result_brojac := nextval('bmv_seq');
       
    RETURN NEXT;
    -- Pozivamo rekurzivno funkciju, ali bez petlje
    RETURN QUERY SELECT * FROM bmv_rec(result_id);
  END LOOP;

  RETURN;
END;
$$;
 ,   DROP FUNCTION iis.bmv_rec(uparent numeric);
       iis          iis    false    8            �            0    0 !   FUNCTION bmv_rec(uparent numeric)    ACL     R   GRANT ALL ON FUNCTION iis.bmv_rec(uparent numeric) TO postgres WITH GRANT OPTION;
          iis          iis    false    978            �           1255    21774 &   fetch_descendants(text, text, numeric)    FUNCTION     �  CREATE FUNCTION iis.fetch_descendants(_veza text, _table text, _parent_id numeric) RETURNS TABLE(descendant_id numeric)
    LANGUAGE plpgsql
    AS $_$
DECLARE
    _sql text;
BEGIN
    _sql := format('
        WITH RECURSIVE descendants AS (
            SELECT event1
            FROM %I
            WHERE event2 = $1
            UNION ALL
            SELECT t.id
            FROM %I t
            JOIN descendants d ON t.event2 = d.event1
        )
        SELECT event1 FROM descendants
		union
		select id
		from	%I
    	where id = $1', _veza, _veza, _table);

    RETURN QUERY EXECUTE _sql USING _parent_id;
END;
$_$;
 R   DROP FUNCTION iis.fetch_descendants(_veza text, _table text, _parent_id numeric);
       iis          iis    false    8            �            0    0 G   FUNCTION fetch_descendants(_veza text, _table text, _parent_id numeric)    ACL     x   GRANT ALL ON FUNCTION iis.fetch_descendants(_veza text, _table text, _parent_id numeric) TO postgres WITH GRANT OPTION;
          iis          iis    false    976            �           1255    21775    generate_json1(numeric)    FUNCTION     \  CREATE FUNCTION iis.generate_json1(uparent numeric) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
  json_result jsonb;
  record_data RECORD;
BEGIN
  IF uParent = 0 THEN
    -- Resetujemo sekvencu samo ako je uParent jednak nuli
    DROP SEQUENCE IF EXISTS bmv_seq;
    CREATE TEMP SEQUENCE bmv_seq;
  END IF;

  json_result := '[]'::jsonb; -- Inicijalizujemo JSON kao prazan niz

  FOR record_data IN (
    SELECT id, parentid, code, text, tp
    FROM bmv
    WHERE parentid IS NULL AND uParent = 0

    UNION ALL

    SELECT b.id, b.parentid, b.code, b.text, b.tp
    FROM bmv b
    WHERE b.parentid = uParent AND uParent > 0
  )
  LOOP
    RAISE NOTICE 'Current id: %', record_data.id; -- Dodajemo ispis trenutne vrednosti id-ja

    IF record_data.id IS NOT NULL THEN
      -- Generišemo JSON objekat za trenutni red
      json_result := jsonb_concat(json_result, jsonb_build_object(
        'key', CAST(record_data.id AS text),
        'data', jsonb_build_object(
          'name', record_data.text,
          'size', '',
          'type', ''
        )
      ));

      -- Pozivamo rekurzivno funkciju za svaki podčvor
      json_result := jsonb_set(json_result, array[quote_ident(CAST(record_data.id AS text)), 'children'], generate_json1(record_data.id));
    END IF;
  END LOOP;

  RETURN json_result;
END;
$$;
 3   DROP FUNCTION iis.generate_json1(uparent numeric);
       iis          iis    false    8            �            0    0 (   FUNCTION generate_json1(uparent numeric)    ACL     Y   GRANT ALL ON FUNCTION iis.generate_json1(uparent numeric) TO postgres WITH GRANT OPTION;
          iis          iis    false    979            �           1255    21776 %   getticartpricecurrf(numeric, numeric)    FUNCTION     �  CREATE FUNCTION iis.getticartpricecurrf(event_id numeric, obj_id numeric) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
  result_text numeric;
BEGIN
  	select ac.value and    
  	INTO result_text
  	from  tic_artcena ac
	where ac.event = event_id 
	and	ac.art = obj_id 
	and   ac.begda <= to_char(current_date, 'yyyymmdd')
	and   ac.endda >= to_char(current_date, 'yyyymmdd');
  
  RETURN result_text;
END;
$$;
 I   DROP FUNCTION iis.getticartpricecurrf(event_id numeric, obj_id numeric);
       iis          iis    false    8            �           1255    21777 !   getvaluebyid(numeric, text, text)    FUNCTION     D  CREATE FUNCTION iis.getvaluebyid(id_value numeric, table_name text, column_name text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
  result_text text;
BEGIN
  EXECUTE 'SELECT ' || column_name || ' FROM '||table_name||' WHERE id = $1'
  INTO result_text
  USING id_value;
  
  RETURN result_text;
END;
$_$;
 U   DROP FUNCTION iis.getvaluebyid(id_value numeric, table_name text, column_name text);
       iis          iis    false    8            �            0    0 J   FUNCTION getvaluebyid(id_value numeric, table_name text, column_name text)    ACL     {   GRANT ALL ON FUNCTION iis.getvaluebyid(id_value numeric, table_name text, column_name text) TO postgres WITH GRANT OPTION;
          iis          iis    false    977            �           1255    21778 '   getvaluebyid(numeric, text, text, text)    FUNCTION     c  CREATE FUNCTION iis.getvaluebyid(id_value numeric, table_name text, column_name text, lang text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
  result_text text;
BEGIN
  EXECUTE 'SELECT ' || column_name || ' FROM '||table_name||' WHERE id = $1 and lang = $2'
  INTO result_text
  USING id_value, lang;
  
  RETURN result_text;
END;
$_$;
 `   DROP FUNCTION iis.getvaluebyid(id_value numeric, table_name text, column_name text, lang text);
       iis          iis    false    8            �            0    0 U   FUNCTION getvaluebyid(id_value numeric, table_name text, column_name text, lang text)    ACL     �   GRANT ALL ON FUNCTION iis.getvaluebyid(id_value numeric, table_name text, column_name text, lang text) TO postgres WITH GRANT OPTION;
          iis          iis    false    980            �           1255    21779    set_created_at()    FUNCTION     �   CREATE FUNCTION iis.set_created_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.created_at = to_char(now(), 'YYYYMMDDHH24MISS');
  NEW.updated_at = to_char(now(), 'YYYYMMDDHH24MISS');
  RETURN NEW;
END;
$$;
 $   DROP FUNCTION iis.set_created_at();
       iis          iis    false    8            �            0    0    FUNCTION set_created_at()    ACL     J   GRANT ALL ON FUNCTION iis.set_created_at() TO postgres WITH GRANT OPTION;
          iis          iis    false    949            �           1255    21780    set_updated_at()    FUNCTION     �   CREATE FUNCTION iis.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = to_char(now(), 'YYYYMMDDHH24MISS');
  RETURN NEW;
END;
$$;
 $   DROP FUNCTION iis.set_updated_at();
       iis          iis    false    8            �            0    0    FUNCTION set_updated_at()    ACL     J   GRANT ALL ON FUNCTION iis.set_updated_at() TO postgres WITH GRANT OPTION;
          iis          iis    false    950            �           1259    21781    aaa    TABLE     �   CREATE TABLE iis.aaa (
    id numeric(10,0) NOT NULL,
    code character varying(200) NOT NULL,
    text character varying(2000) NOT NULL,
    coljson jsonb
);
    DROP TABLE iis.aaa;
       iis         heap    iis    false    8            �            0    0 	   TABLE aaa    ACL     `   GRANT ALL ON TABLE iis.aaa TO PUBLIC;
GRANT ALL ON TABLE iis.aaa TO postgres WITH GRANT OPTION;
          iis          iis    false    700            �           1259    21786    aaa_v    VIEW     r  CREATE VIEW iis.aaa_v AS
 SELECT id,
    code,
    text,
    name,
    value
   FROM ( SELECT aaa.id,
            aaa.code,
            aaa.text,
            (col_elem.value ->> 'name'::text) AS name,
            (col_elem.value ->> 'value'::text) AS value
           FROM (iis.aaa
             CROSS JOIN LATERAL jsonb_array_elements(aaa.coljson) col_elem(value))) aa;
    DROP VIEW iis.aaa_v;
       iis          iis    false    700    700    700    700    8            �            0    0    TABLE aaa_v    ACL     d   GRANT ALL ON TABLE iis.aaa_v TO PUBLIC;
GRANT ALL ON TABLE iis.aaa_v TO postgres WITH GRANT OPTION;
          iis          iis    false    701            �           1259    21790 
   adm_action    TABLE     �   CREATE TABLE iis.adm_action (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(200) NOT NULL,
    text character varying(500) NOT NULL,
    valid numeric(1,0) NOT NULL
);
    DROP TABLE iis.adm_action;
       iis         heap    iis    false    8            �            0    0    TABLE adm_action    COMMENT     X   COMMENT ON TABLE iis.adm_action IS 'Veza izmedju rola, objekata doyvoljenih  i akcija';
          iis          iis    false    702            �            0    0    TABLE adm_action    ACL     n   GRANT ALL ON TABLE iis.adm_action TO PUBLIC;
GRANT ALL ON TABLE iis.adm_action TO postgres WITH GRANT OPTION;
          iis          iis    false    702            �           1259    21795    adm_actionx    TABLE     �   CREATE TABLE iis.adm_actionx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.adm_actionx;
       iis         heap    iis    false    8            �            0    0    TABLE adm_actionx    ACL     p   GRANT ALL ON TABLE iis.adm_actionx TO PUBLIC;
GRANT ALL ON TABLE iis.adm_actionx TO postgres WITH GRANT OPTION;
          iis          iis    false    703            �           1259    21801    adm_action_v    VIEW     �   CREATE VIEW iis.adm_action_v AS
 SELECT a.id,
    a.site,
    a.code,
    a.text,
    a.valid,
    b.text AS texx,
    b.lang
   FROM (iis.adm_action a
     LEFT JOIN iis.adm_actionx b ON (((a.id = b.tableid) AND ((b.lang)::text = 'sr_cyr'::text))));
    DROP VIEW iis.adm_action_v;
       iis          iis    false    702    702    703    703    703    702    702    702    8            �            0    0    TABLE adm_action_v    ACL     r   GRANT ALL ON TABLE iis.adm_action_v TO PUBLIC;
GRANT ALL ON TABLE iis.adm_action_v TO postgres WITH GRANT OPTION;
          iis          iis    false    704            �           1259    21805    adm_actionx_v    VIEW     '  CREATE VIEW iis.adm_actionx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.adm_action aa
     LEFT JOIN iis.adm_actionx aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.adm_actionx_v;
       iis          iis    false    703    703    703    703    702    702    702    702    702    8            �            0    0    TABLE adm_actionx_v    ACL     t   GRANT ALL ON TABLE iis.adm_actionx_v TO PUBLIC;
GRANT ALL ON TABLE iis.adm_actionx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    705            �           1259    21809    adm_blacklist_token    TABLE     �   CREATE TABLE iis.adm_blacklist_token (
    id numeric(20,0) NOT NULL,
    token character varying(2000) NOT NULL,
    expiration character varying(20) NOT NULL
);
 $   DROP TABLE iis.adm_blacklist_token;
       iis         heap    iis    false    8            �            0    0    TABLE adm_blacklist_token    ACL     �   GRANT ALL ON TABLE iis.adm_blacklist_token TO PUBLIC;
GRANT ALL ON TABLE iis.adm_blacklist_token TO postgres WITH GRANT OPTION;
          iis          iis    false    706            �           1259    21814    adm_dbmserr    TABLE     �   CREATE TABLE iis.adm_dbmserr (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(500) NOT NULL,
    text character varying(500) NOT NULL
);
    DROP TABLE iis.adm_dbmserr;
       iis         heap    iis    false    8            �            0    0    TABLE adm_dbmserr    COMMENT     5   COMMENT ON TABLE iis.adm_dbmserr IS 'Ispis greški';
          iis          iis    false    707            �            0    0    TABLE adm_dbmserr    ACL     p   GRANT ALL ON TABLE iis.adm_dbmserr TO PUBLIC;
GRANT ALL ON TABLE iis.adm_dbmserr TO postgres WITH GRANT OPTION;
          iis          iis    false    707            �           1259    21819    adm_dbparameter    TABLE       CREATE TABLE iis.adm_dbparameter (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    text character varying(4000) NOT NULL,
    comment character varying(4000),
    version character varying(20) NOT NULL
);
     DROP TABLE iis.adm_dbparameter;
       iis         heap    iis    false    8            �            0    0    TABLE adm_dbparameter    COMMENT     =   COMMENT ON TABLE iis.adm_dbparameter IS 'Parametri sistem,';
          iis          iis    false    708            �            0    0    TABLE adm_dbparameter    ACL     x   GRANT ALL ON TABLE iis.adm_dbparameter TO PUBLIC;
GRANT ALL ON TABLE iis.adm_dbparameter TO postgres WITH GRANT OPTION;
          iis          iis    false    708            �           1259    21824    adm_message    TABLE     �   CREATE TABLE iis.adm_message (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(20) NOT NULL,
    text character varying(500) NOT NULL
);
    DROP TABLE iis.adm_message;
       iis         heap    iis    false    8            �            0    0    TABLE adm_message    COMMENT     E   COMMENT ON TABLE iis.adm_message IS 'Poruke - aplikativnih procesa';
          iis          iis    false    709            �            0    0    TABLE adm_message    ACL     p   GRANT ALL ON TABLE iis.adm_message TO PUBLIC;
GRANT ALL ON TABLE iis.adm_message TO postgres WITH GRANT OPTION;
          iis          iis    false    709            �           1259    21829    adm_paruser    TABLE     �   CREATE TABLE iis.adm_paruser (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    par numeric(20,0) NOT NULL,
    usr numeric(20,0) NOT NULL,
    begda character varying(10) NOT NULL,
    endda character varying(10) NOT NULL
);
    DROP TABLE iis.adm_paruser;
       iis         heap    iis    false    8            �            0    0    TABLE adm_paruser    COMMENT     l   COMMENT ON TABLE iis.adm_paruser IS 'Partneri korisnika,
Ova tabela mora imati dodatnu programsku logiku';
          iis          iis    false    710            �            0    0    TABLE adm_paruser    ACL     p   GRANT ALL ON TABLE iis.adm_paruser TO PUBLIC;
GRANT ALL ON TABLE iis.adm_paruser TO postgres WITH GRANT OPTION;
          iis          iis    false    710            �           1259    21832    adm_roll    TABLE       CREATE TABLE iis.adm_roll (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(250) NOT NULL,
    text character varying(500) NOT NULL,
    strukturna character varying(1) DEFAULT 'N'::character varying NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_adm_roll1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric]))),
    CONSTRAINT ckc_strukturna_adm_rola CHECK (((strukturna)::text = ANY (ARRAY[('N'::character varying)::text, ('D'::character varying)::text])))
);
    DROP TABLE iis.adm_roll;
       iis         heap    iis    false    8            �            0    0    TABLE adm_roll    COMMENT     ?   COMMENT ON TABLE iis.adm_roll IS 'Korisnicka rola, profil ..';
          iis          iis    false    711            �            0    0    TABLE adm_roll    ACL     j   GRANT ALL ON TABLE iis.adm_roll TO PUBLIC;
GRANT ALL ON TABLE iis.adm_roll TO postgres WITH GRANT OPTION;
          iis          iis    false    711            �           1259    21841    adm_rollact    TABLE     -  CREATE TABLE iis.adm_rollact (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    roll numeric(20,0) NOT NULL,
    action numeric(20,0) NOT NULL,
    cre_action numeric(1,0),
    upd_action numeric(1,0),
    del_action numeric(1,0),
    exe_action numeric(1,0),
    all_action numeric(1,0)
);
    DROP TABLE iis.adm_rollact;
       iis         heap    iis    false    8            �            0    0    TABLE adm_rollact    ACL     p   GRANT ALL ON TABLE iis.adm_rollact TO PUBLIC;
GRANT ALL ON TABLE iis.adm_rollact TO postgres WITH GRANT OPTION;
          iis          iis    false    712            �           1259    21844    adm_rolllink    TABLE     �   CREATE TABLE iis.adm_rolllink (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    roll1 numeric(20,0) NOT NULL,
    roll2 numeric(20,0) NOT NULL,
    link character varying(100) NOT NULL
);
    DROP TABLE iis.adm_rolllink;
       iis         heap    iis    false    8            �            0    0    TABLE adm_rolllink    COMMENT     |   COMMENT ON TABLE iis.adm_rolllink IS 'Nasledjivanje rola - hijerarhija rola
Ne sme se dozvoliti ciklicna prava pristupas';
          iis          iis    false    713            �            0    0    TABLE adm_rolllink    ACL     r   GRANT ALL ON TABLE iis.adm_rolllink TO PUBLIC;
GRANT ALL ON TABLE iis.adm_rolllink TO postgres WITH GRANT OPTION;
          iis          iis    false    713            �           1259    21847    adm_rollstr    TABLE       CREATE TABLE iis.adm_rollstr (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    roll numeric(20,0) NOT NULL,
    onoff numeric(1,0) DEFAULT 1 NOT NULL,
    hijerarhija numeric(1,0) DEFAULT 0 NOT NULL,
    objtp numeric(20,0) NOT NULL,
    obj numeric(20,0) NOT NULL,
    "table" character varying(1000),
    CONSTRAINT ckc_iskljucuje_adm_strr CHECK ((onoff = ANY (ARRAY[(1)::numeric, (0)::numeric]))),
    CONSTRAINT ckc_kumulativ_adm_strr CHECK ((hijerarhija = ANY (ARRAY[(0)::numeric, (1)::numeric])))
);
    DROP TABLE iis.adm_rollstr;
       iis         heap    iis    false    8            �            0    0    TABLE adm_rollstr    COMMENT     �   COMMENT ON TABLE iis.adm_rollstr IS 'Izvedene strukturne role po objektu
- org. jedinici, 
-lokaciji, 
-logickoj lokaciji, 
-dokumentu, 
-zaposlenom ... 

*Može se objekat uklucuivati ili iskljucivati pojedinacno ili hijerarhijski';
          iis          iis    false    714            �            0    0    TABLE adm_rollstr    ACL     p   GRANT ALL ON TABLE iis.adm_rollstr TO PUBLIC;
GRANT ALL ON TABLE iis.adm_rollstr TO postgres WITH GRANT OPTION;
          iis          iis    false    714            �           1259    21856 	   adm_rollx    TABLE     �   CREATE TABLE iis.adm_rollx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.adm_rollx;
       iis         heap    iis    false    8            �            0    0    TABLE adm_rollx    ACL     l   GRANT ALL ON TABLE iis.adm_rollx TO PUBLIC;
GRANT ALL ON TABLE iis.adm_rollx TO postgres WITH GRANT OPTION;
          iis          iis    false    715            �           1259    21862    adm_rollx_v    VIEW     4  CREATE VIEW iis.adm_rollx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.strukturna,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.adm_roll aa
     LEFT JOIN iis.adm_rollx aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.adm_rollx_v;
       iis          iis    false    715    711    711    715    711    711    715    711    711    715    8            �            0    0    TABLE adm_rollx_v    ACL     p   GRANT ALL ON TABLE iis.adm_rollx_v TO PUBLIC;
GRANT ALL ON TABLE iis.adm_rollx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    716            �           1259    21866 	   adm_table    TABLE     �  CREATE TABLE iis.adm_table (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(200) NOT NULL,
    text character varying(500) NOT NULL,
    valid numeric(1,0) NOT NULL,
    module character varying(200),
    base character varying(500),
    url character varying(500),
    dropdown numeric(1,0) DEFAULT 0,
    CONSTRAINT ckc_adm_table2 CHECK (((dropdown IS NULL) OR (dropdown = ANY (ARRAY[(1)::numeric, (0)::numeric]))))
);
    DROP TABLE iis.adm_table;
       iis         heap    iis    false    8            �            0    0    TABLE adm_table    ACL     l   GRANT ALL ON TABLE iis.adm_table TO PUBLIC;
GRANT ALL ON TABLE iis.adm_table TO postgres WITH GRANT OPTION;
          iis          iis    false    717            �           1259    21873    adm_user    TABLE       CREATE TABLE iis.adm_user (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    username character varying(250) NOT NULL,
    password character varying(100) NOT NULL,
    firstname character varying(255),
    lastname character varying(255),
    sapuser character varying(255),
    aduser character varying(255),
    tip character varying(10),
    admin numeric(1,0) DEFAULT 0 NOT NULL,
    mail character varying(250) NOT NULL,
    usergrp numeric(20,0) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    created_at character varying(20) NOT NULL,
    updated_at character varying(20) NOT NULL,
    CONSTRAINT ckc_admin_adm_kor CHECK ((admin = ANY (ARRAY[(1)::numeric, (0)::numeric]))),
    CONSTRAINT ckc_user CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.adm_user;
       iis         heap    iis    false    8             !           0    0    TABLE adm_user    COMMENT     E   COMMENT ON TABLE iis.adm_user IS 'Osnovni podaci korisnika sistema';
          iis          iis    false    718            !           0    0    TABLE adm_user    ACL     j   GRANT ALL ON TABLE iis.adm_user TO PUBLIC;
GRANT ALL ON TABLE iis.adm_user TO postgres WITH GRANT OPTION;
          iis          iis    false    718            �           1259    21882    adm_usergrp    TABLE     .  CREATE TABLE iis.adm_usergrp (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(150) NOT NULL,
    text character varying(500) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_usergrp1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.adm_usergrp;
       iis         heap    iis    false    8            !           0    0    TABLE adm_usergrp    ACL     p   GRANT ALL ON TABLE iis.adm_usergrp TO PUBLIC;
GRANT ALL ON TABLE iis.adm_usergrp TO postgres WITH GRANT OPTION;
          iis          iis    false    719            �           1259    21889 
   adm_user_v    VIEW     �  CREATE VIEW iis.adm_user_v AS
 SELECT u.id,
    u.site,
    u.username,
    u.password,
    u.firstname,
    u.lastname,
    u.sapuser,
    u.aduser,
    u.tip,
    u.admin,
    u.mail,
    u.usergrp,
    u.valid,
    u.created_at,
    u.updated_at,
    ug.id AS gid,
    ug.code AS gcode,
    ug.text AS gtext,
    ug.valid AS gvalid
   FROM iis.adm_user u,
    iis.adm_usergrp ug
  WHERE (ug.id = u.usergrp);
    DROP VIEW iis.adm_user_v;
       iis          iis    false    719    718    718    718    718    718    718    718    718    718    718    718    718    718    718    719    719    719    718    8            !           0    0    TABLE adm_user_v    ACL     n   GRANT ALL ON TABLE iis.adm_user_v TO PUBLIC;
GRANT ALL ON TABLE iis.adm_user_v TO postgres WITH GRANT OPTION;
          iis          iis    false    720            �           1259    21893    adm_useraddr    TABLE     /  CREATE TABLE iis.adm_useraddr (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    usr numeric(20,0) NOT NULL,
    "default" numeric(1,0) DEFAULT 1 NOT NULL,
    adress character varying(1000) NOT NULL,
    city character varying(400),
    zip character varying(10),
    country character varying(400),
    status numeric(1,0) DEFAULT 1,
    CONSTRAINT ckc_adm_useraddr1 CHECK (("default" = ANY (ARRAY[(0)::numeric, (1)::numeric]))),
    CONSTRAINT ckc_adm_useraddr2 CHECK (((status IS NULL) OR (status = ANY (ARRAY[(0)::numeric, (1)::numeric]))))
);
    DROP TABLE iis.adm_useraddr;
       iis         heap    postgres    false    8            �           1259    21902    adm_usergrp_v    VIEW     q   CREATE VIEW iis.adm_usergrp_v AS
 SELECT id,
    site,
    code,
    text,
    valid
   FROM iis.adm_usergrp aa;
    DROP VIEW iis.adm_usergrp_v;
       iis          iis    false    719    719    719    719    719    8            !           0    0    TABLE adm_usergrp_v    ACL     t   GRANT ALL ON TABLE iis.adm_usergrp_v TO PUBLIC;
GRANT ALL ON TABLE iis.adm_usergrp_v TO postgres WITH GRANT OPTION;
          iis          iis    false    722            �           1259    21906    adm_usergrpx    TABLE        CREATE TABLE iis.adm_usergrpx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.adm_usergrpx;
       iis         heap    iis    false    8            !           0    0    TABLE adm_usergrpx    ACL     r   GRANT ALL ON TABLE iis.adm_usergrpx TO PUBLIC;
GRANT ALL ON TABLE iis.adm_usergrpx TO postgres WITH GRANT OPTION;
          iis          iis    false    723            �           1259    21912    adm_usergrpx_v    VIEW     *  CREATE VIEW iis.adm_usergrpx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.adm_usergrp aa
     LEFT JOIN iis.adm_usergrpx aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.adm_usergrpx_v;
       iis          iis    false    719    723    723    723    723    719    719    719    719    8            !           0    0    TABLE adm_usergrpx_v    ACL     v   GRANT ALL ON TABLE iis.adm_usergrpx_v TO PUBLIC;
GRANT ALL ON TABLE iis.adm_usergrpx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    724            �           1259    21916    adm_userlink    TABLE       CREATE TABLE iis.adm_userlink (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    user1 numeric(20,0) NOT NULL,
    user2 character varying(150) NOT NULL,
    begda character varying(10) NOT NULL,
    endda character varying(10) NOT NULL,
    "all" numeric(1,0) NOT NULL
);
    DROP TABLE iis.adm_userlink;
       iis         heap    iis    false    8            !           0    0    TABLE adm_userlink    COMMENT     S   COMMENT ON TABLE iis.adm_userlink IS 'Mapiranje sa korisnicima iz drugih sistema';
          iis          iis    false    725            !           0    0    TABLE adm_userlink    ACL     r   GRANT ALL ON TABLE iis.adm_userlink TO PUBLIC;
GRANT ALL ON TABLE iis.adm_userlink TO postgres WITH GRANT OPTION;
          iis          iis    false    725            �           1259    21919    adm_userlinkpremiss    TABLE     �   CREATE TABLE iis.adm_userlinkpremiss (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    userlink numeric(20,0),
    userpermiss numeric(20,0)
);
 $   DROP TABLE iis.adm_userlinkpremiss;
       iis         heap    iis    false    8            	!           0    0    TABLE adm_userlinkpremiss    ACL     �   GRANT ALL ON TABLE iis.adm_userlinkpremiss TO PUBLIC;
GRANT ALL ON TABLE iis.adm_userlinkpremiss TO postgres WITH GRANT OPTION;
          iis          iis    false    726            �           1259    21922    adm_userloc    TABLE     �   CREATE TABLE iis.adm_userloc (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    usr numeric(20,0) NOT NULL,
    loc numeric(20,0) NOT NULL,
    begda character varying(10) NOT NULL,
    endda character varying(10) NOT NULL
);
    DROP TABLE iis.adm_userloc;
       iis         heap    iis    false    8            
!           0    0    TABLE adm_userloc    ACL     p   GRANT ALL ON TABLE iis.adm_userloc TO PUBLIC;
GRANT ALL ON TABLE iis.adm_userloc TO postgres WITH GRANT OPTION;
          iis          iis    false    727            �           1259    21925    adm_userpermiss    TABLE     �   CREATE TABLE iis.adm_userpermiss (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    usr numeric(20,0) NOT NULL,
    roll numeric(20,0) NOT NULL
);
     DROP TABLE iis.adm_userpermiss;
       iis         heap    iis    false    8            !           0    0    TABLE adm_userpermiss    COMMENT     E   COMMENT ON TABLE iis.adm_userpermiss IS 'Dodeljene role korisniku.';
          iis          iis    false    728            !           0    0    TABLE adm_userpermiss    ACL     x   GRANT ALL ON TABLE iis.adm_userpermiss TO PUBLIC;
GRANT ALL ON TABLE iis.adm_userpermiss TO postgres WITH GRANT OPTION;
          iis          iis    false    728            �           1259    21928    adm_userpermiss_vr    VIEW       CREATE VIEW iis.adm_userpermiss_vr AS
 SELECT u.id,
    u.site,
    u.usr,
    u.roll,
    r.id AS rid,
    r.code AS rcode,
    r.text AS rtext,
    r.strukturna,
    r.valid AS rvalid
   FROM iis.adm_userpermiss u,
    iis.adm_roll r
  WHERE (r.id = u.roll);
 "   DROP VIEW iis.adm_userpermiss_vr;
       iis          iis    false    711    711    711    711    711    728    728    728    728    8            !           0    0    TABLE adm_userpermiss_vr    ACL     ~   GRANT ALL ON TABLE iis.adm_userpermiss_vr TO PUBLIC;
GRANT ALL ON TABLE iis.adm_userpermiss_vr TO postgres WITH GRANT OPTION;
          iis          iis    false    729            �           1259    21932    adm_userpermiss_vu    VIEW     �   CREATE VIEW iis.adm_userpermiss_vu AS
 SELECT u.id,
    u.site,
    u.usr,
    u.roll,
    r.id AS oid,
    r.username,
    r.mail,
    r.firstname,
    r.lastname
   FROM iis.adm_userpermiss u,
    iis.adm_user r
  WHERE (r.id = u.usr);
 "   DROP VIEW iis.adm_userpermiss_vu;
       iis          iis    false    718    728    728    728    718    718    718    718    728    8            !           0    0    TABLE adm_userpermiss_vu    ACL     ~   GRANT ALL ON TABLE iis.adm_userpermiss_vu TO PUBLIC;
GRANT ALL ON TABLE iis.adm_userpermiss_vu TO postgres WITH GRANT OPTION;
          iis          iis    false    730            �           1259    21936    cmn_obj    TABLE     �  CREATE TABLE iis.cmn_obj (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(150) NOT NULL,
    text character varying(500) NOT NULL,
    tp numeric(20,0) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    color character varying(20),
    icon character varying(20),
    CONSTRAINT ckc_cmn_objekat1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.cmn_obj;
       iis         heap    iis    false    8            !           0    0    TABLE cmn_obj    COMMENT     k   COMMENT ON TABLE iis.cmn_obj IS 'Objekat koga nasledjuju org. jed, lokacija, radna mesta, teritorije ...';
          iis          iis    false    731            !           0    0    TABLE cmn_obj    ACL     h   GRANT ALL ON TABLE iis.cmn_obj TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_obj TO postgres WITH GRANT OPTION;
          iis          iis    false    731            �           1259    21943    cmn_objlink    TABLE     �  CREATE TABLE iis.cmn_objlink (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    objtp1 numeric(20,0) NOT NULL,
    obj1 numeric(20,0) NOT NULL,
    objtp2 numeric(20,0) NOT NULL,
    obj2 numeric(20,0) NOT NULL,
    cmn_link numeric(20,0),
    direction character varying(1) DEFAULT 'A'::character varying NOT NULL,
    code character varying(2),
    text character varying(1000),
    um numeric(20,0),
    begda character varying(10) NOT NULL,
    endda character varying(10) NOT NULL,
    hijerarhija numeric(1,0),
    onoff numeric(1,0),
    CONSTRAINT ckc_zs_objekatveza2 CHECK (((direction)::text = ANY (ARRAY[('A'::character varying)::text, ('B'::character varying)::text])))
);
    DROP TABLE iis.cmn_objlink;
       iis         heap    iis    false    8            !           0    0    TABLE cmn_objlink    COMMENT     =   COMMENT ON TABLE iis.cmn_objlink IS 'Veza izmedju objekata';
          iis          iis    false    732            !           0    0    TABLE cmn_objlink    ACL     p   GRANT ALL ON TABLE iis.cmn_objlink TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_objlink TO postgres WITH GRANT OPTION;
          iis          iis    false    732            �           1259    21950    bmv    VIEW     )  CREATE VIEW iis.bmv AS
 SELECT id,
    parentid,
    code,
    text,
    tp
   FROM ( SELECT cmn_obj.id,
            NULL::numeric AS parentid,
            cmn_obj.code,
            cmn_obj.text,
            cmn_obj.tp
           FROM iis.cmn_obj
          WHERE (cmn_obj.id = ('1681750967634497536'::bigint)::numeric)
        UNION
         SELECT co.obj1 AS id,
            co.obj2 AS parentid,
            o.code,
            o.text,
            o.tp
           FROM iis.cmn_objlink co,
            iis.cmn_obj o
          WHERE (co.obj1 = o.id)) a;
    DROP VIEW iis.bmv;
       iis          iis    false    731    731    731    731    732    732    8            !           0    0 	   TABLE bmv    ACL     `   GRANT ALL ON TABLE iis.bmv TO PUBLIC;
GRANT ALL ON TABLE iis.bmv TO postgres WITH GRANT OPTION;
          iis          iis    false    733            �           1259    21955 	   cmn_ccard    TABLE     *  CREATE TABLE iis.cmn_ccard (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(20) NOT NULL,
    text character varying(60) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_cmn_tgp1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.cmn_ccard;
       iis         heap    iis    false    8            �           1259    21960 
   cmn_ccardx    TABLE     �   CREATE TABLE iis.cmn_ccardx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.cmn_ccardx;
       iis         heap    iis    false    8            �           1259    21966    cmn_curr    TABLE     	  CREATE TABLE iis.cmn_curr (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(10) NOT NULL,
    text character varying(255) NOT NULL,
    tp character varying(1) DEFAULT '3'::character varying NOT NULL,
    country numeric(20,0) NOT NULL,
    begda character varying(10) NOT NULL,
    endda character varying(10) NOT NULL,
    CONSTRAINT ckc_tip_zs_valut CHECK (((tp)::text = ANY (ARRAY[('1'::character varying)::text, ('2'::character varying)::text, ('3'::character varying)::text])))
);
    DROP TABLE iis.cmn_curr;
       iis         heap    iis    false    8            !           0    0    TABLE cmn_curr    COMMENT     6   COMMENT ON TABLE iis.cmn_curr IS 'Evidencija valuta';
          iis          iis    false    736            !           0    0    TABLE cmn_curr    ACL     j   GRANT ALL ON TABLE iis.cmn_curr TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_curr TO postgres WITH GRANT OPTION;
          iis          iis    false    736            �           1259    21971    cmn_currrate    TABLE     5  CREATE TABLE iis.cmn_currrate (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    curr1 numeric(20,0) NOT NULL,
    curr2 numeric(20,0) NOT NULL,
    begda character varying(10) NOT NULL,
    endda character varying(10) NOT NULL,
    rate numeric(18,5) NOT NULL,
    parity numeric(10,0) NOT NULL
);
    DROP TABLE iis.cmn_currrate;
       iis         heap    iis    false    8            !           0    0    TABLE cmn_currrate    COMMENT     5   COMMENT ON TABLE iis.cmn_currrate IS 'Kursna lista';
          iis          iis    false    737            !           0    0    TABLE cmn_currrate    ACL     r   GRANT ALL ON TABLE iis.cmn_currrate TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_currrate TO postgres WITH GRANT OPTION;
          iis          iis    false    737            �           1259    21974 	   cmn_currx    TABLE     �   CREATE TABLE iis.cmn_currx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.cmn_currx;
       iis         heap    iis    false    8            !           0    0    TABLE cmn_currx    ACL     l   GRANT ALL ON TABLE iis.cmn_currx TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_currx TO postgres WITH GRANT OPTION;
          iis          iis    false    738            �           1259    21980    cmn_currx_v    VIEW     J  CREATE VIEW iis.cmn_currx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.tp,
    aa.country,
    aa.begda,
    aa.endda,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.cmn_curr aa
     LEFT JOIN iis.cmn_currx aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.cmn_currx_v;
       iis          iis    false    736    738    738    738    738    736    736    736    736    736    736    736    8            !           0    0    TABLE cmn_currx_v    ACL     p   GRANT ALL ON TABLE iis.cmn_currx_v TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_currx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    739            �           1259    21984 	   tic_doctp    TABLE     �  CREATE TABLE iis.tic_doctp (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    text character varying(500) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    duguje numeric(1,0) DEFAULT 1 NOT NULL,
    znak character varying(1) NOT NULL,
    CONSTRAINT ckc_tic_doctg1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric]))),
    CONSTRAINT ckc_tic_doctg2 CHECK ((duguje = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.tic_doctp;
       iis         heap    iis    false    8            !           0    0    TABLE tic_doctp    ACL     l   GRANT ALL ON TABLE iis.tic_doctp TO PUBLIC;
GRANT ALL ON TABLE iis.tic_doctp TO postgres WITH GRANT OPTION;
          iis          iis    false    740            �           1259    21993 
   tic_doctpx    TABLE     �   CREATE TABLE iis.tic_doctpx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.tic_doctpx;
       iis         heap    iis    false    8            !           0    0    TABLE tic_doctpx    ACL     n   GRANT ALL ON TABLE iis.tic_doctpx TO PUBLIC;
GRANT ALL ON TABLE iis.tic_doctpx TO postgres WITH GRANT OPTION;
          iis          iis    false    741            �           1259    21999    cmn_doctpx_v    VIEW     @  CREATE VIEW iis.cmn_doctpx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.valid,
    aa.duguje,
    aa.znak,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.tic_doctp aa
     LEFT JOIN iis.tic_doctpx aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.cmn_doctpx_v;
       iis          iis    false    740    740    740    740    740    741    741    741    741    740    740    8            !           0    0    TABLE cmn_doctpx_v    ACL     r   GRANT ALL ON TABLE iis.cmn_doctpx_v TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_doctpx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    742            �           1259    22003    cmn_inputtp    TABLE     )  CREATE TABLE iis.cmn_inputtp (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(10) NOT NULL,
    text character varying(60) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_modul CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.cmn_inputtp;
       iis         heap    iis    false    8            !           0    0    TABLE cmn_inputtp    ACL     p   GRANT ALL ON TABLE iis.cmn_inputtp TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_inputtp TO postgres WITH GRANT OPTION;
          iis          iis    false    743            �           1259    22008    cmn_inputtpx    TABLE        CREATE TABLE iis.cmn_inputtpx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.cmn_inputtpx;
       iis         heap    iis    false    8            !           0    0    TABLE cmn_inputtpx    ACL     r   GRANT ALL ON TABLE iis.cmn_inputtpx TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_inputtpx TO postgres WITH GRANT OPTION;
          iis          iis    false    744            �           1259    22014    cmn_inputtpx_v    VIEW     *  CREATE VIEW iis.cmn_inputtpx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.cmn_inputtp aa
     LEFT JOIN iis.cmn_inputtpx aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.cmn_inputtpx_v;
       iis          iis    false    744    744    743    743    743    743    744    744    743    8            !           0    0    TABLE cmn_inputtpx_v    ACL     v   GRANT ALL ON TABLE iis.cmn_inputtpx_v TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_inputtpx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    745            �           1259    22018    cmn_link    TABLE     u  CREATE TABLE iis.cmn_link (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    text character varying(500) NOT NULL,
    objtp1 numeric(20,0) NOT NULL,
    objtp2 numeric(20,0) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_cmn_vezatip1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.cmn_link;
       iis         heap    iis    false    8             !           0    0    TABLE cmn_link    COMMENT     b   COMMENT ON TABLE iis.cmn_link IS 'Tipovi veza objekat npr O-O org1-org2, O-R-Z org-rm-zaposleni';
          iis          iis    false    746            !!           0    0    TABLE cmn_link    ACL     j   GRANT ALL ON TABLE iis.cmn_link TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_link TO postgres WITH GRANT OPTION;
          iis          iis    false    746            �           1259    22025 	   cmn_linkx    TABLE     �   CREATE TABLE iis.cmn_linkx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.cmn_linkx;
       iis         heap    iis    false    8            "!           0    0    TABLE cmn_linkx    ACL     l   GRANT ALL ON TABLE iis.cmn_linkx TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_linkx TO postgres WITH GRANT OPTION;
          iis          iis    false    747            �           1259    22031    cmn_linkx_v    VIEW     ?  CREATE VIEW iis.cmn_linkx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.objtp1,
    aa.objtp2,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.cmn_link aa
     LEFT JOIN iis.cmn_linkx aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.cmn_linkx_v;
       iis          iis    false    747    747    747    746    746    746    746    746    746    746    747    8            #!           0    0    TABLE cmn_linkx_v    ACL     p   GRANT ALL ON TABLE iis.cmn_linkx_v TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_linkx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    748            �           1259    22035    cmn_loc    TABLE     �  CREATE TABLE iis.cmn_loc (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    text character varying(500) NOT NULL,
    longtext character varying(4000),
    tp numeric(20,0) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    graftp numeric(20,0),
    latlongs json,
    radius numeric(15,5),
    color character varying(100),
    fillcolor character varying(100),
    originfillcolor character varying(100),
    rownum character varying(100),
    seatnum character varying(100),
    icon character varying(20),
    CONSTRAINT ckc_cmn_loc1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.cmn_loc;
       iis         heap    iis    false    8            $!           0    0    TABLE cmn_loc    COMMENT     >   COMMENT ON TABLE iis.cmn_loc IS 'Lokacije,  na teritorijama';
          iis          iis    false    749            %!           0    0    TABLE cmn_loc    ACL     h   GRANT ALL ON TABLE iis.cmn_loc TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_loc TO postgres WITH GRANT OPTION;
          iis          iis    false    749            �           1259    22042 
   cmn_locatt    TABLE     0  CREATE TABLE iis.cmn_locatt (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    text character varying(500) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_cmn_locatt1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.cmn_locatt;
       iis         heap    iis    false    8            &!           0    0    TABLE cmn_locatt    ACL     n   GRANT ALL ON TABLE iis.cmn_locatt TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_locatt TO postgres WITH GRANT OPTION;
          iis          iis    false    750            �           1259    22049    cmn_locatts    TABLE       CREATE TABLE iis.cmn_locatts (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    loc numeric(20,0) NOT NULL,
    locatt numeric(20,0) NOT NULL,
    text character varying(500) NOT NULL,
    begda character varying(10) NOT NULL,
    endda character varying(10) NOT NULL
);
    DROP TABLE iis.cmn_locatts;
       iis         heap    iis    false    8            '!           0    0    TABLE cmn_locatts    ACL     p   GRANT ALL ON TABLE iis.cmn_locatts TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_locatts TO postgres WITH GRANT OPTION;
          iis          iis    false    751            �           1259    22054    cmn_locattx    TABLE     �   CREATE TABLE iis.cmn_locattx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.cmn_locattx;
       iis         heap    iis    false    8            (!           0    0    TABLE cmn_locattx    ACL     p   GRANT ALL ON TABLE iis.cmn_locattx TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_locattx TO postgres WITH GRANT OPTION;
          iis          iis    false    752            �           1259    22060    cmn_locattx_v    VIEW     '  CREATE VIEW iis.cmn_locattx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.cmn_locatt aa
     LEFT JOIN iis.cmn_locattx aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.cmn_locattx_v;
       iis          iis    false    752    752    752    752    750    750    750    750    750    8            )!           0    0    TABLE cmn_locattx_v    ACL     t   GRANT ALL ON TABLE iis.cmn_locattx_v TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_locattx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    753            �           1259    22064    cmn_loclink    TABLE     �  CREATE TABLE iis.cmn_loclink (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tp numeric(20,0) NOT NULL,
    loctp1 numeric(20,0) NOT NULL,
    loc1 numeric(20,0) NOT NULL,
    loctp2 numeric(20,0) NOT NULL,
    loc2 numeric(20,0) NOT NULL,
    val character varying(2500),
    begda character varying(10) NOT NULL,
    endda character varying(10) NOT NULL,
    hijerarhija numeric(1,0) DEFAULT 0,
    onoff numeric(1,0) DEFAULT 1,
    color character varying(100),
    icon character varying(100),
    CONSTRAINT ckc_iskljucuje_adm_strr CHECK (((onoff IS NULL) OR (onoff = ANY (ARRAY[(1)::numeric, (0)::numeric])))),
    CONSTRAINT ckc_kumulativ_adm_strr CHECK (((hijerarhija IS NULL) OR (hijerarhija = ANY (ARRAY[(0)::numeric, (1)::numeric]))))
);
    DROP TABLE iis.cmn_loclink;
       iis         heap    iis    false    8            *!           0    0    TABLE cmn_loclink    ACL     p   GRANT ALL ON TABLE iis.cmn_loclink TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_loclink TO postgres WITH GRANT OPTION;
          iis          iis    false    754            �           1259    22073    cmn_loclinktp    TABLE     6  CREATE TABLE iis.cmn_loclinktp (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    text character varying(500) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_cmn_loclinktp1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.cmn_loclinktp;
       iis         heap    iis    false    8            +!           0    0    TABLE cmn_loclinktp    ACL     t   GRANT ALL ON TABLE iis.cmn_loclinktp TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_loclinktp TO postgres WITH GRANT OPTION;
          iis          iis    false    755            �           1259    22080    cmn_loclinktpx    TABLE       CREATE TABLE iis.cmn_loclinktpx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.cmn_loclinktpx;
       iis         heap    iis    false    8            ,!           0    0    TABLE cmn_loclinktpx    ACL     v   GRANT ALL ON TABLE iis.cmn_loclinktpx TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_loclinktpx TO postgres WITH GRANT OPTION;
          iis          iis    false    756            �           1259    22086    cmn_loclinktpx_v    VIEW     0  CREATE VIEW iis.cmn_loclinktpx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.cmn_loclinktp aa
     LEFT JOIN iis.cmn_loclinktpx aa2 ON ((aa.id = aa2.tableid)));
     DROP VIEW iis.cmn_loclinktpx_v;
       iis          iis    false    756    756    756    756    755    755    755    755    755    8            -!           0    0    TABLE cmn_loclinktpx_v    ACL     z   GRANT ALL ON TABLE iis.cmn_loclinktpx_v TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_loclinktpx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    757            �           1259    22090 
   cmn_locobj    TABLE     �   CREATE TABLE iis.cmn_locobj (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    loc numeric(20,0) NOT NULL,
    obj numeric(20,0) NOT NULL,
    begda character varying(10),
    endda character varying(10)
);
    DROP TABLE iis.cmn_locobj;
       iis         heap    iis    false    8            .!           0    0    TABLE cmn_locobj    COMMENT     P   COMMENT ON TABLE iis.cmn_locobj IS 'Veza objekat - lokacija za prava pristupa';
          iis          iis    false    758            /!           0    0    TABLE cmn_locobj    ACL     n   GRANT ALL ON TABLE iis.cmn_locobj TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_locobj TO postgres WITH GRANT OPTION;
          iis          iis    false    758            �           1259    22093 	   cmn_loctp    TABLE     O  CREATE TABLE iis.cmn_loctp (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    text character varying(500) NOT NULL,
    icon character varying(100),
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_cmn_loctp1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.cmn_loctp;
       iis         heap    iis    false    8            0!           0    0    TABLE cmn_loctp    COMMENT     �   COMMENT ON TABLE iis.cmn_loctp IS 'VENUE
-- SCENA
-- ulaz
-- -- BLOK
Nisu izdvojeni posebno kako bi moglo da se kontroliše pravo na rad sa odredenim blokovima';
          iis          iis    false    759            1!           0    0    TABLE cmn_loctp    ACL     l   GRANT ALL ON TABLE iis.cmn_loctp TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_loctp TO postgres WITH GRANT OPTION;
          iis          iis    false    759            �           1259    22100 
   cmn_loctpx    TABLE     �   CREATE TABLE iis.cmn_loctpx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.cmn_loctpx;
       iis         heap    iis    false    8            2!           0    0    TABLE cmn_loctpx    ACL     n   GRANT ALL ON TABLE iis.cmn_loctpx TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_loctpx TO postgres WITH GRANT OPTION;
          iis          iis    false    760            �           1259    22106    cmn_loctpx_v    VIEW     $  CREATE VIEW iis.cmn_loctpx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.cmn_loctp aa
     LEFT JOIN iis.cmn_loctpx aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.cmn_loctpx_v;
       iis          iis    false    759    759    759    759    759    760    760    760    760    8            3!           0    0    TABLE cmn_loctpx_v    ACL     r   GRANT ALL ON TABLE iis.cmn_loctpx_v TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_loctpx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    761            �           1259    22110    cmn_locx    TABLE     �   CREATE TABLE iis.cmn_locx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.cmn_locx;
       iis         heap    iis    false    8            4!           0    0    TABLE cmn_locx    ACL     j   GRANT ALL ON TABLE iis.cmn_locx TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_locx TO postgres WITH GRANT OPTION;
          iis          iis    false    762            �           1259    22116 
   cmn_locx_v    VIEW     U  CREATE VIEW iis.cmn_locx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.longtext,
    aa.tp,
    aa.valid,
    aa.color,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase,
    aa.icon
   FROM (iis.cmn_loc aa
     LEFT JOIN iis.cmn_locx aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.cmn_locx_v;
       iis          postgres    false    749    749    749    749    749    749    749    762    762    762    762    749    749    8            �           1259    22121    cmn_menu    TABLE     �  CREATE TABLE iis.cmn_menu (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(250) NOT NULL,
    text character varying(1000) NOT NULL,
    parentid numeric(20,0),
    link character varying(1000),
    akction character varying(40),
    module numeric(20,0) NOT NULL,
    icon character varying(250),
    "user" numeric(20,0),
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_menu1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.cmn_menu;
       iis         heap    iis    false    8            5!           0    0    TABLE cmn_menu    COMMENT     9   COMMENT ON TABLE iis.cmn_menu IS 'Glavni meni  modula.';
          iis          iis    false    764            6!           0    0    TABLE cmn_menu    ACL     j   GRANT ALL ON TABLE iis.cmn_menu TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_menu TO postgres WITH GRANT OPTION;
          iis          iis    false    764            �           1259    22128 	   cmn_menux    TABLE     �   CREATE TABLE iis.cmn_menux (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.cmn_menux;
       iis         heap    iis    false    8            7!           0    0    TABLE cmn_menux    ACL     l   GRANT ALL ON TABLE iis.cmn_menux TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_menux TO postgres WITH GRANT OPTION;
          iis          iis    false    765            �           1259    22134    cmn_menux_v    VIEW     z  CREATE VIEW iis.cmn_menux_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.parentid,
    aa.link,
    aa.akction,
    aa.module,
    aa.icon,
    aa."user",
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.cmn_menu aa
     LEFT JOIN iis.cmn_menux aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.cmn_menux_v;
       iis          iis    false    765    764    764    764    764    764    764    764    764    764    764    764    765    765    765    8            8!           0    0    TABLE cmn_menux_v    ACL     p   GRANT ALL ON TABLE iis.cmn_menux_v TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_menux_v TO postgres WITH GRANT OPTION;
          iis          iis    false    766            �           1259    22139 
   cmn_module    TABLE     B  CREATE TABLE iis.cmn_module (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(10) NOT NULL,
    text character varying(60) NOT NULL,
    app_id numeric(20,0),
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_modul CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.cmn_module;
       iis         heap    iis    false    8            9!           0    0    TABLE cmn_module    COMMENT     M   COMMENT ON TABLE iis.cmn_module IS 'Evidencija internih programskih modula';
          iis          iis    false    767            :!           0    0    TABLE cmn_module    ACL     n   GRANT ALL ON TABLE iis.cmn_module TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_module TO postgres WITH GRANT OPTION;
          iis          iis    false    767                        1259    22144    cmn_modulex    TABLE     �   CREATE TABLE iis.cmn_modulex (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.cmn_modulex;
       iis         heap    iis    false    8            ;!           0    0    TABLE cmn_modulex    ACL     p   GRANT ALL ON TABLE iis.cmn_modulex TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_modulex TO postgres WITH GRANT OPTION;
          iis          iis    false    768                       1259    22150    cmn_modulex_v    VIEW     6  CREATE VIEW iis.cmn_modulex_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.app_id,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.cmn_module aa
     LEFT JOIN iis.cmn_modulex aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.cmn_modulex_v;
       iis          iis    false    767    767    767    767    767    767    768    768    768    768    8            <!           0    0    TABLE cmn_modulex_v    ACL     t   GRANT ALL ON TABLE iis.cmn_modulex_v TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_modulex_v TO postgres WITH GRANT OPTION;
          iis          iis    false    769                       1259    22154 
   cmn_objatt    TABLE     P  CREATE TABLE iis.cmn_objatt (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(150) NOT NULL,
    text character varying(500) NOT NULL,
    cmn_objatttp numeric(20,0),
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_cmn_objatt1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.cmn_objatt;
       iis         heap    iis    false    8            =!           0    0    TABLE cmn_objatt    COMMENT     Z   COMMENT ON TABLE iis.cmn_objatt IS 'Prodajna mreža
Objekat, 
Lokacija,
Organizacija';
          iis          iis    false    770            >!           0    0    TABLE cmn_objatt    ACL     n   GRANT ALL ON TABLE iis.cmn_objatt TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_objatt TO postgres WITH GRANT OPTION;
          iis          iis    false    770                       1259    22161    cmn_objatts    TABLE       CREATE TABLE iis.cmn_objatts (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    obj numeric(20,0) NOT NULL,
    cmn_objatt numeric(20,0) NOT NULL,
    begda character varying(10) NOT NULL,
    endda character varying(10) NOT NULL,
    value character varying(1000)
);
    DROP TABLE iis.cmn_objatts;
       iis         heap    iis    false    8            ?!           0    0    TABLE cmn_objatts    ACL     p   GRANT ALL ON TABLE iis.cmn_objatts TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_objatts TO postgres WITH GRANT OPTION;
          iis          iis    false    771                       1259    22166    cmn_objatttp    TABLE     4  CREATE TABLE iis.cmn_objatttp (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(150) NOT NULL,
    text character varying(500) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_cmn_objatttp1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.cmn_objatttp;
       iis         heap    iis    false    8            @!           0    0    TABLE cmn_objatttp    ACL     r   GRANT ALL ON TABLE iis.cmn_objatttp TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_objatttp TO postgres WITH GRANT OPTION;
          iis          iis    false    772                       1259    22173    cmn_objatttpx    TABLE       CREATE TABLE iis.cmn_objatttpx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.cmn_objatttpx;
       iis         heap    iis    false    8            A!           0    0    TABLE cmn_objatttpx    ACL     t   GRANT ALL ON TABLE iis.cmn_objatttpx TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_objatttpx TO postgres WITH GRANT OPTION;
          iis          iis    false    773                       1259    22179    cmn_objatttpx_v    VIEW     -  CREATE VIEW iis.cmn_objatttpx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.cmn_objatttp aa
     LEFT JOIN iis.cmn_objatttpx aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.cmn_objatttpx_v;
       iis          iis    false    773    772    772    772    773    773    772    773    772    8            B!           0    0    TABLE cmn_objatttpx_v    ACL     x   GRANT ALL ON TABLE iis.cmn_objatttpx_v TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_objatttpx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    774                       1259    22183    cmn_objattx    TABLE     �   CREATE TABLE iis.cmn_objattx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.cmn_objattx;
       iis         heap    iis    false    8            C!           0    0    TABLE cmn_objattx    ACL     p   GRANT ALL ON TABLE iis.cmn_objattx TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_objattx TO postgres WITH GRANT OPTION;
          iis          iis    false    775                       1259    22189    cmn_objattx_v    VIEW     <  CREATE VIEW iis.cmn_objattx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.cmn_objatttp,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.cmn_objatt aa
     LEFT JOIN iis.cmn_objattx aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.cmn_objattx_v;
       iis          iis    false    770    775    775    775    770    770    770    770    770    775    8            D!           0    0    TABLE cmn_objattx_v    ACL     t   GRANT ALL ON TABLE iis.cmn_objattx_v TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_objattx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    776            	           1259    22193    cmn_objlink_arr    TABLE     `  CREATE TABLE iis.cmn_objlink_arr (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    objtp1 numeric(20,0),
    obj1 numeric(20,0) NOT NULL,
    objtp2 numeric(20,0),
    obj2 numeric(20,0) NOT NULL,
    level numeric(20,0) NOT NULL,
    code numeric(20,2),
    begda character varying(10) NOT NULL,
    endda character varying(10) NOT NULL
);
     DROP TABLE iis.cmn_objlink_arr;
       iis         heap    iis    false    8            E!           0    0    TABLE cmn_objlink_arr    COMMENT     Y   COMMENT ON TABLE iis.cmn_objlink_arr IS 'Tabela za konverziju hijerarhijske veze u niz';
          iis          iis    false    777            F!           0    0    TABLE cmn_objlink_arr    ACL     x   GRANT ALL ON TABLE iis.cmn_objlink_arr TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_objlink_arr TO postgres WITH GRANT OPTION;
          iis          iis    false    777            
           1259    22196 	   cmn_objtp    TABLE     Y  CREATE TABLE iis.cmn_objtp (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    text character varying(500) NOT NULL,
    adm_table numeric(20,0) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_cmn_objekattip1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.cmn_objtp;
       iis         heap    iis    false    8            G!           0    0    TABLE cmn_objtp    COMMENT     1   COMMENT ON TABLE iis.cmn_objtp IS 'Tip objekta';
          iis          iis    false    778            H!           0    0    TABLE cmn_objtp    ACL     l   GRANT ALL ON TABLE iis.cmn_objtp TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_objtp TO postgres WITH GRANT OPTION;
          iis          iis    false    778                       1259    22203 
   cmn_objtpx    TABLE     �   CREATE TABLE iis.cmn_objtpx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.cmn_objtpx;
       iis         heap    iis    false    8            I!           0    0    TABLE cmn_objtpx    ACL     n   GRANT ALL ON TABLE iis.cmn_objtpx TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_objtpx TO postgres WITH GRANT OPTION;
          iis          iis    false    779                       1259    22209    cmn_objtpx_v    VIEW     6  CREATE VIEW iis.cmn_objtpx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.adm_table,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.cmn_objtp aa
     LEFT JOIN iis.cmn_objtpx aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.cmn_objtpx_v;
       iis          iis    false    778    778    778    778    778    779    779    779    779    778    8            J!           0    0    TABLE cmn_objtpx_v    ACL     r   GRANT ALL ON TABLE iis.cmn_objtpx_v TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_objtpx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    780                       1259    22213    cmn_objx    TABLE     �   CREATE TABLE iis.cmn_objx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.cmn_objx;
       iis         heap    iis    false    8            K!           0    0    TABLE cmn_objx    ACL     j   GRANT ALL ON TABLE iis.cmn_objx TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_objx TO postgres WITH GRANT OPTION;
          iis          iis    false    781                       1259    22219 
   cmn_objx_v    VIEW     D  CREATE VIEW iis.cmn_objx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.tp,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase,
    aa.color,
    aa.icon
   FROM (iis.cmn_obj aa
     LEFT JOIN iis.cmn_objx aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.cmn_objx_v;
       iis          iis    false    781    781    781    731    781    731    731    731    731    731    731    731    8            L!           0    0    TABLE cmn_objx_v    ACL     n   GRANT ALL ON TABLE iis.cmn_objx_v TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_objx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    782                       1259    22223    cmn_par    TABLE     N  CREATE TABLE iis.cmn_par (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    tp numeric(20,0) NOT NULL,
    text character varying(500) NOT NULL,
    short character varying(30),
    address character varying(60),
    place character varying(250),
    postcode character varying(10),
    tel character varying(250),
    activity character varying(50),
    pib character varying(250),
    idnum character varying(250),
    pdvnum character varying(250),
    begda character varying(10) NOT NULL,
    endda character varying(10) NOT NULL
);
    DROP TABLE iis.cmn_par;
       iis         heap    iis    false    8            M!           0    0    COLUMN cmn_par.activity    COMMENT     7   COMMENT ON COLUMN iis.cmn_par.activity IS 'Delatnost';
          iis          iis    false    783            N!           0    0    COLUMN cmn_par.pib    COMMENT     9   COMMENT ON COLUMN iis.cmn_par.pib IS 'Da li je u PDV-u';
          iis          iis    false    783            O!           0    0    COLUMN cmn_par.idnum    COMMENT     7   COMMENT ON COLUMN iis.cmn_par.idnum IS 'Maticni broj';
          iis          iis    false    783            P!           0    0    COLUMN cmn_par.pdvnum    COMMENT     4   COMMENT ON COLUMN iis.cmn_par.pdvnum IS 'Broj PDV';
          iis          iis    false    783            Q!           0    0    TABLE cmn_par    ACL     h   GRANT ALL ON TABLE iis.cmn_par TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_par TO postgres WITH GRANT OPTION;
          iis          iis    false    783                       1259    22228    cmn_paraccount    TABLE       CREATE TABLE iis.cmn_paraccount (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    cmn_par numeric(20,0) NOT NULL,
    bank numeric(20,0) NOT NULL,
    account character varying(50) NOT NULL,
    brojpartije character varying(50),
    glavni character varying(1) DEFAULT 'N'::character varying NOT NULL,
    begda character varying(10) NOT NULL,
    endda character varying(10) NOT NULL,
    CONSTRAINT ckc_zs_komitentiziro1 CHECK (((glavni)::text = ANY (ARRAY[('D'::character varying)::text, ('N'::character varying)::text])))
);
    DROP TABLE iis.cmn_paraccount;
       iis         heap    iis    false    8            R!           0    0    TABLE cmn_paraccount    ACL     v   GRANT ALL ON TABLE iis.cmn_paraccount TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_paraccount TO postgres WITH GRANT OPTION;
          iis          iis    false    784                       1259    22233 
   cmn_paratt    TABLE     0  CREATE TABLE iis.cmn_paratt (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    text character varying(250) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_cmn_paratt1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.cmn_paratt;
       iis         heap    iis    false    8            S!           0    0    TABLE cmn_paratt    COMMENT     S   COMMENT ON TABLE iis.cmn_paratt IS 'Dodatne osobine partnera, rabat, kartice ...';
          iis          iis    false    785            T!           0    0    TABLE cmn_paratt    ACL     n   GRANT ALL ON TABLE iis.cmn_paratt TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_paratt TO postgres WITH GRANT OPTION;
          iis          iis    false    785                       1259    22238    cmn_paratts    TABLE       CREATE TABLE iis.cmn_paratts (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    par numeric(20,0) NOT NULL,
    att numeric(20,0) NOT NULL,
    text character varying(4000),
    begda character varying(10) NOT NULL,
    endda character varying(10) NOT NULL
);
    DROP TABLE iis.cmn_paratts;
       iis         heap    iis    false    8            U!           0    0    TABLE cmn_paratts    ACL     p   GRANT ALL ON TABLE iis.cmn_paratts TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_paratts TO postgres WITH GRANT OPTION;
          iis          iis    false    786                       1259    22243    cmn_parattx    TABLE     �   CREATE TABLE iis.cmn_parattx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.cmn_parattx;
       iis         heap    iis    false    8            V!           0    0    TABLE cmn_parattx    ACL     p   GRANT ALL ON TABLE iis.cmn_parattx TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_parattx TO postgres WITH GRANT OPTION;
          iis          iis    false    787                       1259    22249    cmn_parattx_v    VIEW     '  CREATE VIEW iis.cmn_parattx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.cmn_paratt aa
     LEFT JOIN iis.cmn_parattx aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.cmn_parattx_v;
       iis          iis    false    787    787    787    787    785    785    785    785    785    8            W!           0    0    TABLE cmn_parattx_v    ACL     t   GRANT ALL ON TABLE iis.cmn_parattx_v TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_parattx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    788                       1259    22253    cmn_parcontact    TABLE     �  CREATE TABLE iis.cmn_parcontact (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    cmn_par numeric(20,0) NOT NULL,
    tp numeric(20,0) NOT NULL,
    person character varying(500) NOT NULL,
    long character varying(500),
    tel character varying(500),
    mail character varying(250),
    other character varying(500),
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_cmn_parcontact CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.cmn_parcontact;
       iis         heap    iis    false    8            X!           0    0    TABLE cmn_parcontact    ACL     v   GRANT ALL ON TABLE iis.cmn_parcontact TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_parcontact TO postgres WITH GRANT OPTION;
          iis          iis    false    789                       1259    22260    cmn_parcontacttp    TABLE     �  CREATE TABLE iis.cmn_parcontacttp (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    text character varying(500) NOT NULL,
    sys_code character varying(100) DEFAULT 'X'::character varying NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_cmn_parcontacttp1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
 !   DROP TABLE iis.cmn_parcontacttp;
       iis         heap    iis    false    8            Y!           0    0    TABLE cmn_parcontacttp    COMMENT     a   COMMENT ON TABLE iis.cmn_parcontacttp IS 'Tip kootakt lica, vlasnik, direktor, sekretarica ...';
          iis          iis    false    790            Z!           0    0     COLUMN cmn_parcontacttp.sys_code    COMMENT     [   COMMENT ON COLUMN iis.cmn_parcontacttp.sys_code IS 'Sifra za izdvajnje posebnih korisika';
          iis          iis    false    790            [!           0    0    TABLE cmn_parcontacttp    ACL     z   GRANT ALL ON TABLE iis.cmn_parcontacttp TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_parcontacttp TO postgres WITH GRANT OPTION;
          iis          iis    false    790                       1259    22268    cmn_parcontacttpx    TABLE       CREATE TABLE iis.cmn_parcontacttpx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
 "   DROP TABLE iis.cmn_parcontacttpx;
       iis         heap    iis    false    8            \!           0    0    TABLE cmn_parcontacttpx    ACL     |   GRANT ALL ON TABLE iis.cmn_parcontacttpx TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_parcontacttpx TO postgres WITH GRANT OPTION;
          iis          iis    false    791                       1259    22274    cmn_parcontacttpx_v    VIEW     J  CREATE VIEW iis.cmn_parcontacttpx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.sys_code,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.cmn_parcontacttp aa
     LEFT JOIN iis.cmn_parcontacttpx aa2 ON ((aa.id = aa2.tableid)));
 #   DROP VIEW iis.cmn_parcontacttpx_v;
       iis          iis    false    791    791    791    790    790    790    790    790    790    791    8            ]!           0    0    TABLE cmn_parcontacttpx_v    ACL     �   GRANT ALL ON TABLE iis.cmn_parcontacttpx_v TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_parcontacttpx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    792                       1259    22278    cmn_parlink    TABLE     �   CREATE TABLE iis.cmn_parlink (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    par1 numeric(20,0) NOT NULL,
    par2 numeric(20,0) NOT NULL,
    text character varying(2500),
    begda character varying(10),
    endda character varying(10)
);
    DROP TABLE iis.cmn_parlink;
       iis         heap    iis    false    8            ^!           0    0    TABLE cmn_parlink    COMMENT     ^   COMMENT ON TABLE iis.cmn_parlink IS 'Odnos izmedju partnera povezanih lica, predstavništva';
          iis          iis    false    793            _!           0    0    TABLE cmn_parlink    ACL     p   GRANT ALL ON TABLE iis.cmn_parlink TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_parlink TO postgres WITH GRANT OPTION;
          iis          iis    false    793                       1259    22283 	   cmn_partp    TABLE     .  CREATE TABLE iis.cmn_partp (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    text character varying(250) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_cmn_partp1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.cmn_partp;
       iis         heap    iis    false    8            `!           0    0    TABLE cmn_partp    ACL     l   GRANT ALL ON TABLE iis.cmn_partp TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_partp TO postgres WITH GRANT OPTION;
          iis          iis    false    794                       1259    22288 
   cmn_partpx    TABLE     �   CREATE TABLE iis.cmn_partpx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.cmn_partpx;
       iis         heap    iis    false    8            a!           0    0    TABLE cmn_partpx    ACL     n   GRANT ALL ON TABLE iis.cmn_partpx TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_partpx TO postgres WITH GRANT OPTION;
          iis          iis    false    795                       1259    22294    cmn_partpx_v    VIEW     $  CREATE VIEW iis.cmn_partpx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.cmn_partp aa
     LEFT JOIN iis.cmn_partpx aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.cmn_partpx_v;
       iis          iis    false    794    794    794    794    795    795    795    795    794    8            b!           0    0    TABLE cmn_partpx_v    ACL     r   GRANT ALL ON TABLE iis.cmn_partpx_v TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_partpx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    796                       1259    22298    cmn_parx    TABLE     �   CREATE TABLE iis.cmn_parx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.cmn_parx;
       iis         heap    iis    false    8            c!           0    0    TABLE cmn_parx    ACL     j   GRANT ALL ON TABLE iis.cmn_parx TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_parx TO postgres WITH GRANT OPTION;
          iis          iis    false    797                       1259    22304 
   cmn_parx_v    VIEW     �  CREATE VIEW iis.cmn_parx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    aa.tp,
    COALESCE(aa2.text, aa.text) AS text,
    aa.short,
    aa.address,
    aa.place,
    aa.postcode,
    aa.tel,
    aa.activity,
    aa.pib,
    aa.idnum,
    aa.pdvnum,
    aa.begda,
    aa.endda,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.cmn_par aa
     LEFT JOIN iis.cmn_parx aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.cmn_parx_v;
       iis          iis    false    783    797    783    783    783    783    783    797    783    783    783    783    783    783    783    783    783    783    797    797    8            d!           0    0    TABLE cmn_parx_v    ACL     n   GRANT ALL ON TABLE iis.cmn_parx_v TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_parx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    798                       1259    22309    cmn_paymenttp    TABLE     .  CREATE TABLE iis.cmn_paymenttp (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(20) NOT NULL,
    text character varying(60) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_cmn_tgp1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.cmn_paymenttp;
       iis         heap    iis    false    8            e!           0    0    TABLE cmn_paymenttp    ACL     t   GRANT ALL ON TABLE iis.cmn_paymenttp TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_paymenttp TO postgres WITH GRANT OPTION;
          iis          iis    false    799                        1259    22314    cmn_paymenttpx    TABLE       CREATE TABLE iis.cmn_paymenttpx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.cmn_paymenttpx;
       iis         heap    iis    false    8            f!           0    0    TABLE cmn_paymenttpx    ACL     v   GRANT ALL ON TABLE iis.cmn_paymenttpx TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_paymenttpx TO postgres WITH GRANT OPTION;
          iis          iis    false    800            !           1259    22320    cmn_paymenttpx_v    VIEW     0  CREATE VIEW iis.cmn_paymenttpx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.cmn_paymenttp aa
     LEFT JOIN iis.cmn_paymenttpx aa2 ON ((aa.id = aa2.tableid)));
     DROP VIEW iis.cmn_paymenttpx_v;
       iis          iis    false    800    800    799    799    799    799    799    800    800    8            g!           0    0    TABLE cmn_paymenttpx_v    ACL     z   GRANT ALL ON TABLE iis.cmn_paymenttpx_v TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_paymenttpx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    801            "           1259    22324    cmn_site    TABLE     ,  CREATE TABLE iis.cmn_site (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(150) NOT NULL,
    text character varying(500) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_cmn_sajt1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.cmn_site;
       iis         heap    iis    false    8            h!           0    0    TABLE cmn_site    ACL     j   GRANT ALL ON TABLE iis.cmn_site TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_site TO postgres WITH GRANT OPTION;
          iis          iis    false    802            #           1259    22331    cmn_tax    TABLE     L  CREATE TABLE iis.cmn_tax (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(20) NOT NULL,
    text character varying(60) NOT NULL,
    country numeric(20,0) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_cmn_tax1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.cmn_tax;
       iis         heap    iis    false    8            i!           0    0    TABLE cmn_tax    ACL     h   GRANT ALL ON TABLE iis.cmn_tax TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_tax TO postgres WITH GRANT OPTION;
          iis          iis    false    803            $           1259    22336    cmn_taxrate    TABLE     �   CREATE TABLE iis.cmn_taxrate (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tax numeric(20,0) NOT NULL,
    rate numeric(20,5) NOT NULL,
    begda character varying(10) NOT NULL,
    endda character varying(10) NOT NULL
);
    DROP TABLE iis.cmn_taxrate;
       iis         heap    iis    false    8            j!           0    0    TABLE cmn_taxrate    ACL     p   GRANT ALL ON TABLE iis.cmn_taxrate TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_taxrate TO postgres WITH GRANT OPTION;
          iis          iis    false    804            %           1259    22339    cmn_taxx    TABLE     �   CREATE TABLE iis.cmn_taxx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.cmn_taxx;
       iis         heap    iis    false    8            k!           0    0    TABLE cmn_taxx    ACL     j   GRANT ALL ON TABLE iis.cmn_taxx TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_taxx TO postgres WITH GRANT OPTION;
          iis          iis    false    805            &           1259    22345 
   cmn_taxx_v    VIEW     .  CREATE VIEW iis.cmn_taxx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.country,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.cmn_tax aa
     LEFT JOIN iis.cmn_taxx aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.cmn_taxx_v;
       iis          iis    false    803    803    805    803    805    805    805    803    803    803    8            l!           0    0    TABLE cmn_taxx_v    ACL     n   GRANT ALL ON TABLE iis.cmn_taxx_v TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_taxx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    806            '           1259    22349    cmn_terr    TABLE     7  CREATE TABLE iis.cmn_terr (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(150) NOT NULL,
    text character varying(250) NOT NULL,
    tp numeric(20,0) NOT NULL,
    postcode character varying(50),
    begda character varying(10) NOT NULL,
    endda character varying(10)
);
    DROP TABLE iis.cmn_terr;
       iis         heap    iis    false    8            m!           0    0    TABLE cmn_terr    COMMENT     _   COMMENT ON TABLE iis.cmn_terr IS 'Teritorijalne celine drzava, grad, opstina, mz, oblast ...';
          iis          iis    false    807            n!           0    0    TABLE cmn_terr    ACL     j   GRANT ALL ON TABLE iis.cmn_terr TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_terr TO postgres WITH GRANT OPTION;
          iis          iis    false    807            (           1259    22352    cmn_terratt    TABLE     2  CREATE TABLE iis.cmn_terratt (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    text character varying(500) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_cmn_terratt1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.cmn_terratt;
       iis         heap    iis    false    8            o!           0    0    TABLE cmn_terratt    ACL     p   GRANT ALL ON TABLE iis.cmn_terratt TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_terratt TO postgres WITH GRANT OPTION;
          iis          iis    false    808            )           1259    22359    cmn_terratts    TABLE       CREATE TABLE iis.cmn_terratts (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    loc numeric(20,0) NOT NULL,
    att numeric(20,0) NOT NULL,
    text character varying(2500),
    begda character varying(10) NOT NULL,
    endda character varying(10) NOT NULL
);
    DROP TABLE iis.cmn_terratts;
       iis         heap    iis    false    8            p!           0    0    TABLE cmn_terratts    ACL     r   GRANT ALL ON TABLE iis.cmn_terratts TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_terratts TO postgres WITH GRANT OPTION;
          iis          iis    false    809            *           1259    22364    cmn_terrattx    TABLE        CREATE TABLE iis.cmn_terrattx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.cmn_terrattx;
       iis         heap    iis    false    8            q!           0    0    TABLE cmn_terrattx    ACL     r   GRANT ALL ON TABLE iis.cmn_terrattx TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_terrattx TO postgres WITH GRANT OPTION;
          iis          iis    false    810            +           1259    22370    cmn_terrattx_v    VIEW     *  CREATE VIEW iis.cmn_terrattx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.cmn_terratt aa
     LEFT JOIN iis.cmn_terrattx aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.cmn_terrattx_v;
       iis          iis    false    808    808    808    808    808    810    810    810    810    8            r!           0    0    TABLE cmn_terrattx_v    ACL     v   GRANT ALL ON TABLE iis.cmn_terrattx_v TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_terrattx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    811            ,           1259    22374    cmn_terrlink    TABLE       CREATE TABLE iis.cmn_terrlink (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    terr1 numeric(20,0) NOT NULL,
    terr2 numeric(20,0) NOT NULL,
    text character varying(250),
    begda character varying(10) NOT NULL,
    endda character varying(10) NOT NULL
);
    DROP TABLE iis.cmn_terrlink;
       iis         heap    iis    false    8            s!           0    0    TABLE cmn_terrlink    ACL     r   GRANT ALL ON TABLE iis.cmn_terrlink TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_terrlink TO postgres WITH GRANT OPTION;
          iis          iis    false    812            -           1259    22377    cmn_terrlinktp    TABLE     8  CREATE TABLE iis.cmn_terrlinktp (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(150) NOT NULL,
    text character varying(250) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_cmn_terrlinktp1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.cmn_terrlinktp;
       iis         heap    iis    false    8            t!           0    0    TABLE cmn_terrlinktp    COMMENT     �   COMMENT ON TABLE iis.cmn_terrlinktp IS 'Logicka veza izmedu teritorijalnih celina. Moguca je razlicita veza izmedu teritorijalnih celina.';
          iis          iis    false    813            u!           0    0    TABLE cmn_terrlinktp    ACL     v   GRANT ALL ON TABLE iis.cmn_terrlinktp TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_terrlinktp TO postgres WITH GRANT OPTION;
          iis          iis    false    813            .           1259    22382    cmn_terrlinktpx    TABLE       CREATE TABLE iis.cmn_terrlinktpx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
     DROP TABLE iis.cmn_terrlinktpx;
       iis         heap    iis    false    8            v!           0    0    TABLE cmn_terrlinktpx    ACL     x   GRANT ALL ON TABLE iis.cmn_terrlinktpx TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_terrlinktpx TO postgres WITH GRANT OPTION;
          iis          iis    false    814            /           1259    22388    cmn_terrlinktpx_v    VIEW     3  CREATE VIEW iis.cmn_terrlinktpx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.cmn_terrlinktp aa
     LEFT JOIN iis.cmn_terrlinktpx aa2 ON ((aa.id = aa2.tableid)));
 !   DROP VIEW iis.cmn_terrlinktpx_v;
       iis          iis    false    813    813    813    813    813    814    814    814    814    8            w!           0    0    TABLE cmn_terrlinktpx_v    ACL     |   GRANT ALL ON TABLE iis.cmn_terrlinktpx_v TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_terrlinktpx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    815            0           1259    22392    cmn_terrloc    TABLE     �   CREATE TABLE iis.cmn_terrloc (
    id numeric(20,0) NOT NULL,
    terr numeric(20,0) NOT NULL,
    loc numeric(20,0) NOT NULL,
    begda character varying(10) NOT NULL,
    endda character varying(10) NOT NULL
);
    DROP TABLE iis.cmn_terrloc;
       iis         heap    iis    false    8            x!           0    0    TABLE cmn_terrloc    ACL     p   GRANT ALL ON TABLE iis.cmn_terrloc TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_terrloc TO postgres WITH GRANT OPTION;
          iis          iis    false    816            1           1259    22395 
   cmn_terrtp    TABLE     .  CREATE TABLE iis.cmn_terrtp (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    text character varying(250) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_cmn_terr1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.cmn_terrtp;
       iis         heap    iis    false    8            y!           0    0    TABLE cmn_terrtp    COMMENT     W   COMMENT ON TABLE iis.cmn_terrtp IS 'Tip teritorije drzava, grad, opstina, mz, oblast';
          iis          iis    false    817            z!           0    0    TABLE cmn_terrtp    ACL     n   GRANT ALL ON TABLE iis.cmn_terrtp TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_terrtp TO postgres WITH GRANT OPTION;
          iis          iis    false    817            2           1259    22400    cmn_terrtpx    TABLE     �   CREATE TABLE iis.cmn_terrtpx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.cmn_terrtpx;
       iis         heap    iis    false    8            {!           0    0    TABLE cmn_terrtpx    ACL     p   GRANT ALL ON TABLE iis.cmn_terrtpx TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_terrtpx TO postgres WITH GRANT OPTION;
          iis          iis    false    818            3           1259    22406    cmn_terrtpx_v    VIEW     '  CREATE VIEW iis.cmn_terrtpx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.cmn_terrtp aa
     LEFT JOIN iis.cmn_terrtpx aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.cmn_terrtpx_v;
       iis          iis    false    818    818    817    817    817    817    817    818    818    8            |!           0    0    TABLE cmn_terrtpx_v    ACL     t   GRANT ALL ON TABLE iis.cmn_terrtpx_v TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_terrtpx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    819            4           1259    22410 	   cmn_terrx    TABLE     �   CREATE TABLE iis.cmn_terrx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.cmn_terrx;
       iis         heap    iis    false    8            }!           0    0    TABLE cmn_terrx    ACL     l   GRANT ALL ON TABLE iis.cmn_terrx TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_terrx TO postgres WITH GRANT OPTION;
          iis          iis    false    820            5           1259    22416    cmn_terrx_v    VIEW     K  CREATE VIEW iis.cmn_terrx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.tp,
    aa.postcode,
    aa.begda,
    aa.endda,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.cmn_terr aa
     LEFT JOIN iis.cmn_terrx aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.cmn_terrx_v;
       iis          iis    false    807    820    820    820    820    807    807    807    807    807    807    807    8            ~!           0    0    TABLE cmn_terrx_v    ACL     p   GRANT ALL ON TABLE iis.cmn_terrx_v TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_terrx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    821            6           1259    22420    cmn_tgp    TABLE     L  CREATE TABLE iis.cmn_tgp (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(20) NOT NULL,
    text character varying(60) NOT NULL,
    country numeric(20,0) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_cmn_tgp1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.cmn_tgp;
       iis         heap    iis    false    8            !           0    0    TABLE cmn_tgp    ACL     h   GRANT ALL ON TABLE iis.cmn_tgp TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_tgp TO postgres WITH GRANT OPTION;
          iis          iis    false    822            7           1259    22425 
   cmn_tgptax    TABLE     �   CREATE TABLE iis.cmn_tgptax (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tgp numeric(20,0) NOT NULL,
    tax numeric(20,0) NOT NULL,
    begda character varying(10) NOT NULL,
    endda character varying(10) NOT NULL
);
    DROP TABLE iis.cmn_tgptax;
       iis         heap    iis    false    8            �!           0    0    TABLE cmn_tgptax    ACL     n   GRANT ALL ON TABLE iis.cmn_tgptax TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_tgptax TO postgres WITH GRANT OPTION;
          iis          iis    false    823            8           1259    22428    cmn_tgpx    TABLE     �   CREATE TABLE iis.cmn_tgpx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.cmn_tgpx;
       iis         heap    iis    false    8            �!           0    0    TABLE cmn_tgpx    ACL     j   GRANT ALL ON TABLE iis.cmn_tgpx TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_tgpx TO postgres WITH GRANT OPTION;
          iis          iis    false    824            9           1259    22434 
   cmn_tgpx_v    VIEW     .  CREATE VIEW iis.cmn_tgpx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.country,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.cmn_tgp aa
     LEFT JOIN iis.cmn_tgpx aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.cmn_tgpx_v;
       iis          iis    false    822    824    824    824    824    822    822    822    822    822    8            �!           0    0    TABLE cmn_tgpx_v    ACL     n   GRANT ALL ON TABLE iis.cmn_tgpx_v TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_tgpx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    825            :           1259    22438    cmn_um    TABLE     '  CREATE TABLE iis.cmn_um (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(20) NOT NULL,
    text character varying(250) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_cmn_um1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.cmn_um;
       iis         heap    iis    false    8            �!           0    0    TABLE cmn_um    COMMENT     0   COMMENT ON TABLE iis.cmn_um IS 'Jedinica mere';
          iis          iis    false    826            �!           0    0    TABLE cmn_um    ACL     f   GRANT ALL ON TABLE iis.cmn_um TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_um TO postgres WITH GRANT OPTION;
          iis          iis    false    826            ;           1259    22443    cmn_umparity    TABLE       CREATE TABLE iis.cmn_umparity (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    um1 numeric(20,0) NOT NULL,
    um2 numeric(20,0) NOT NULL,
    parity numeric(15,2) NOT NULL,
    begda character varying(10),
    datumod2 character varying(10)
);
    DROP TABLE iis.cmn_umparity;
       iis         heap    iis    false    8            �!           0    0    TABLE cmn_umparity    ACL     r   GRANT ALL ON TABLE iis.cmn_umparity TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_umparity TO postgres WITH GRANT OPTION;
          iis          iis    false    827            <           1259    22446    cmn_umx    TABLE     �   CREATE TABLE iis.cmn_umx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.cmn_umx;
       iis         heap    iis    false    8            �!           0    0    TABLE cmn_umx    ACL     h   GRANT ALL ON TABLE iis.cmn_umx TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_umx TO postgres WITH GRANT OPTION;
          iis          iis    false    828            =           1259    22452 	   cmn_umx_v    VIEW       CREATE VIEW iis.cmn_umx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.cmn_um aa
     LEFT JOIN iis.cmn_umx aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.cmn_umx_v;
       iis          iis    false    828    828    828    828    826    826    826    826    826    8            �!           0    0    TABLE cmn_umx_v    ACL     l   GRANT ALL ON TABLE iis.cmn_umx_v TO PUBLIC;
GRANT ALL ON TABLE iis.cmn_umx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    829            >           1259    22456    moja_tabela    TABLE     K   CREATE TABLE iis.moja_tabela (
    id integer NOT NULL,
    podaci json
);
    DROP TABLE iis.moja_tabela;
       iis         heap    iis    false    8            �!           0    0    TABLE moja_tabela    ACL     p   GRANT ALL ON TABLE iis.moja_tabela TO PUBLIC;
GRANT ALL ON TABLE iis.moja_tabela TO postgres WITH GRANT OPTION;
          iis          iis    false    830            ?           1259    22461    moja_tabela_id_seq    SEQUENCE     �   CREATE SEQUENCE iis.moja_tabela_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE iis.moja_tabela_id_seq;
       iis          iis    false    8    830            �!           0    0    moja_tabela_id_seq    SEQUENCE OWNED BY     C   ALTER SEQUENCE iis.moja_tabela_id_seq OWNED BY iis.moja_tabela.id;
          iis          iis    false    831            �!           0    0    SEQUENCE moja_tabela_id_seq    ACL     �   GRANT ALL ON SEQUENCE iis.moja_tabela_id_seq TO PUBLIC;
GRANT ALL ON SEQUENCE iis.moja_tabela_id_seq TO postgres WITH GRANT OPTION;
          iis          iis    false    831            @           1259    22462    objtree_json_v    VIEW       CREATE VIEW iis.objtree_json_v AS
 WITH RECURSIVE d2 AS (
         SELECT b.id,
            b.parentid,
            b.code,
            b.text,
            b.tp,
            0 AS level
           FROM iis.bmv b
          WHERE (b.parentid IS NULL)
        UNION ALL
         SELECT b.id,
            b.parentid,
            b.code,
            b.text,
            b.tp,
            (d2.level + 1)
           FROM (iis.bmv b
             JOIN d2 ON ((d2.id = b.parentid)))
        ), d3 AS (
         SELECT d2.id,
            d2.parentid,
            d2.code,
            d2.text,
            d2.tp,
            d2.level,
            NULL::jsonb AS children
           FROM d2
          WHERE (d2.level = ( SELECT max(d2_1.level) AS max
                   FROM d2 d2_1))
        UNION
         SELECT (branch.branch_parent).id AS id,
            (branch.branch_parent).parentid AS parentid,
            (branch.branch_parent).code AS code,
            (branch.branch_parent).text AS text,
            (branch.branch_parent).tp AS tp,
            (branch.branch_parent).level AS level,
            jsonb_strip_nulls(jsonb_agg(((branch.branch_child - 'parentid'::text) - 'level'::text) ORDER BY (branch.branch_child ->> 'text'::text)) FILTER (WHERE ((branch.branch_child ->> 'parentid'::text) = ((branch.branch_parent).id)::text))) AS jsonb_strip_nulls
           FROM ( SELECT branch_parent.*::record AS branch_parent,
                    to_jsonb(branch_child.*) AS branch_child
                   FROM (d2 branch_parent
                     JOIN d3 branch_child ON ((branch_child.level = (branch_parent.level + 1))))) branch
          GROUP BY branch.branch_parent
        )
 SELECT jsonb_pretty(jsonb_agg(((to_jsonb(d3.*) - 'parentid'::text) - 'level'::text))) AS tree
   FROM d3
  WHERE (level = 0);
    DROP VIEW iis.objtree_json_v;
       iis          iis    false    733    733    733    733    733    8            �!           0    0    TABLE objtree_json_v    ACL     v   GRANT ALL ON TABLE iis.objtree_json_v TO PUBLIC;
GRANT ALL ON TABLE iis.objtree_json_v TO postgres WITH GRANT OPTION;
          iis          iis    false    832            A           1259    22467 
   tic_agenda    TABLE     �  CREATE TABLE iis.tic_agenda (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    text character varying(500) NOT NULL,
    tg numeric(20,0) NOT NULL,
    begtm character varying(5) NOT NULL,
    endtm character varying(5) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_cmn_seattpatt1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.tic_agenda;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_agenda    ACL     n   GRANT ALL ON TABLE iis.tic_agenda TO PUBLIC;
GRANT ALL ON TABLE iis.tic_agenda TO postgres WITH GRANT OPTION;
          iis          iis    false    833            B           1259    22474    tic_agendatp    TABLE     4  CREATE TABLE iis.tic_agendatp (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    text character varying(500) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_tic_agendatp1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.tic_agendatp;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_agendatp    ACL     r   GRANT ALL ON TABLE iis.tic_agendatp TO PUBLIC;
GRANT ALL ON TABLE iis.tic_agendatp TO postgres WITH GRANT OPTION;
          iis          iis    false    834            C           1259    22481    tic_agendatpx    TABLE       CREATE TABLE iis.tic_agendatpx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.tic_agendatpx;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_agendatpx    ACL     t   GRANT ALL ON TABLE iis.tic_agendatpx TO PUBLIC;
GRANT ALL ON TABLE iis.tic_agendatpx TO postgres WITH GRANT OPTION;
          iis          iis    false    835            D           1259    22487    tic_agendatpx_v    VIEW     -  CREATE VIEW iis.tic_agendatpx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.tic_agendatp aa
     LEFT JOIN iis.tic_agendatpx aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.tic_agendatpx_v;
       iis          iis    false    834    834    834    835    835    834    835    835    834    8            �!           0    0    TABLE tic_agendatpx_v    ACL     x   GRANT ALL ON TABLE iis.tic_agendatpx_v TO PUBLIC;
GRANT ALL ON TABLE iis.tic_agendatpx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    836            E           1259    22491    tic_agendax    TABLE     �   CREATE TABLE iis.tic_agendax (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.tic_agendax;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_agendax    ACL     p   GRANT ALL ON TABLE iis.tic_agendax TO PUBLIC;
GRANT ALL ON TABLE iis.tic_agendax TO postgres WITH GRANT OPTION;
          iis          iis    false    837            F           1259    22497    tic_agendax_v    VIEW     N  CREATE VIEW iis.tic_agendax_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.tg,
    aa.begtm,
    aa.endtm,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.tic_agenda aa
     LEFT JOIN iis.tic_agendax aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.tic_agendax_v;
       iis          iis    false    833    837    833    837    833    833    837    837    833    833    833    833    8            �!           0    0    TABLE tic_agendax_v    ACL     t   GRANT ALL ON TABLE iis.tic_agendax_v TO PUBLIC;
GRANT ALL ON TABLE iis.tic_agendax_v TO postgres WITH GRANT OPTION;
          iis          iis    false    838            G           1259    22501    tic_art    TABLE     I  CREATE TABLE iis.tic_art (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    text character varying(500) NOT NULL,
    tp numeric(20,0) NOT NULL,
    um numeric(20,0) NOT NULL,
    tgp numeric(20,0) NOT NULL,
    eancode character varying(100),
    qrcode character varying(100),
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    grp numeric(20,0) NOT NULL,
    color character varying(20),
    icon character varying(20),
    amount numeric(1,0),
    CONSTRAINT ckc_tic_tic1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.tic_art;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_art    COMMENT     �   COMMENT ON TABLE iis.tic_art IS 'Artikal, karta numerisana vezana za dogadjaj, odredjenog tipa 
Artikal moze da bue vezan za sediste a i ne mora, kao na primer za dostavu
Ako je vezan oda se odnosi na broj sedista na toj lokaciji';
          iis          iis    false    839            �!           0    0    TABLE tic_art    ACL     h   GRANT ALL ON TABLE iis.tic_art TO PUBLIC;
GRANT ALL ON TABLE iis.tic_art TO postgres WITH GRANT OPTION;
          iis          iis    false    839            H           1259    22508    tic_artcena    TABLE     j  CREATE TABLE iis.tic_artcena (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    event numeric(20,0),
    art numeric(20,0) NOT NULL,
    cena numeric(20,0) NOT NULL,
    value numeric(16,5) NOT NULL,
    terr numeric(20,0) NOT NULL,
    begda character varying(10) NOT NULL,
    endda character varying(10) NOT NULL,
    curr numeric(20,0) NOT NULL
);
    DROP TABLE iis.tic_artcena;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_artcena    ACL     p   GRANT ALL ON TABLE iis.tic_artcena TO PUBLIC;
GRANT ALL ON TABLE iis.tic_artcena TO postgres WITH GRANT OPTION;
          iis          iis    false    840            I           1259    22511 
   tic_artgrp    TABLE     3  CREATE TABLE iis.tic_artgrp (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    text character varying(500) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_tic_ticartgrp1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.tic_artgrp;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_artgrp    ACL     n   GRANT ALL ON TABLE iis.tic_artgrp TO PUBLIC;
GRANT ALL ON TABLE iis.tic_artgrp TO postgres WITH GRANT OPTION;
          iis          iis    false    841            J           1259    22518    tic_artgrpx    TABLE     �   CREATE TABLE iis.tic_artgrpx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.tic_artgrpx;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_artgrpx    ACL     p   GRANT ALL ON TABLE iis.tic_artgrpx TO PUBLIC;
GRANT ALL ON TABLE iis.tic_artgrpx TO postgres WITH GRANT OPTION;
          iis          iis    false    842            K           1259    22524    tic_artgrpx_v    VIEW     '  CREATE VIEW iis.tic_artgrpx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.tic_artgrp aa
     LEFT JOIN iis.tic_artgrpx aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.tic_artgrpx_v;
       iis          iis    false    842    842    842    842    841    841    841    841    841    8            �!           0    0    TABLE tic_artgrpx_v    ACL     t   GRANT ALL ON TABLE iis.tic_artgrpx_v TO PUBLIC;
GRANT ALL ON TABLE iis.tic_artgrpx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    843            L           1259    22528    tic_artlink    TABLE     �   CREATE TABLE iis.tic_artlink (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    art1 numeric(20,0) NOT NULL,
    art2 numeric(20,0) NOT NULL,
    tp character varying(2) NOT NULL
);
    DROP TABLE iis.tic_artlink;
       iis         heap    iis    false    8            M           1259    22531 
   tic_artloc    TABLE     �   CREATE TABLE iis.tic_artloc (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    art numeric(20,0) NOT NULL,
    loc numeric(20,0) NOT NULL,
    begda character varying(10) NOT NULL,
    endda character varying(10) NOT NULL
);
    DROP TABLE iis.tic_artloc;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_artloc    ACL     n   GRANT ALL ON TABLE iis.tic_artloc TO PUBLIC;
GRANT ALL ON TABLE iis.tic_artloc TO postgres WITH GRANT OPTION;
          iis          iis    false    845            N           1259    22534    tic_artprivilege    TABLE       CREATE TABLE iis.tic_artprivilege (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    art numeric(20,0) NOT NULL,
    privilege numeric(20,0) NOT NULL,
    begda character varying(10) NOT NULL,
    endda character varying(10) NOT NULL,
    value character varying(1000)
);
 !   DROP TABLE iis.tic_artprivilege;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_artprivilege    ACL     z   GRANT ALL ON TABLE iis.tic_artprivilege TO PUBLIC;
GRANT ALL ON TABLE iis.tic_artprivilege TO postgres WITH GRANT OPTION;
          iis          iis    false    846            O           1259    22539 
   tic_arttax    TABLE     �   CREATE TABLE iis.tic_arttax (
    id numeric(20,0) NOT NULL,
    art numeric(20,0) NOT NULL,
    tax numeric(20,0) NOT NULL,
    value character varying(1000),
    begda character varying(10) NOT NULL,
    endda character varying(10) NOT NULL
);
    DROP TABLE iis.tic_arttax;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_arttax    ACL     n   GRANT ALL ON TABLE iis.tic_arttax TO PUBLIC;
GRANT ALL ON TABLE iis.tic_arttax TO postgres WITH GRANT OPTION;
          iis          iis    false    847            P           1259    22544 	   tic_arttp    TABLE     .  CREATE TABLE iis.tic_arttp (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    text character varying(500) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_tic_tictp1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.tic_arttp;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_arttp    ACL     l   GRANT ALL ON TABLE iis.tic_arttp TO PUBLIC;
GRANT ALL ON TABLE iis.tic_arttp TO postgres WITH GRANT OPTION;
          iis          iis    false    848            Q           1259    22551 
   tic_arttpx    TABLE     �   CREATE TABLE iis.tic_arttpx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.tic_arttpx;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_arttpx    ACL     n   GRANT ALL ON TABLE iis.tic_arttpx TO PUBLIC;
GRANT ALL ON TABLE iis.tic_arttpx TO postgres WITH GRANT OPTION;
          iis          iis    false    849            R           1259    22557    tic_arttpx_v    VIEW     $  CREATE VIEW iis.tic_arttpx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.tic_arttp aa
     LEFT JOIN iis.tic_arttpx aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.tic_arttpx_v;
       iis          iis    false    849    848    848    848    848    848    849    849    849    8            �!           0    0    TABLE tic_arttpx_v    ACL     r   GRANT ALL ON TABLE iis.tic_arttpx_v TO PUBLIC;
GRANT ALL ON TABLE iis.tic_arttpx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    850            S           1259    22561    tic_artx    TABLE     �   CREATE TABLE iis.tic_artx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.tic_artx;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_artx    ACL     j   GRANT ALL ON TABLE iis.tic_artx TO PUBLIC;
GRANT ALL ON TABLE iis.tic_artx TO postgres WITH GRANT OPTION;
          iis          iis    false    851            T           1259    22567 
   tic_artx_v    VIEW     �  CREATE VIEW iis.tic_artx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.tp,
    aa.um,
    aa.tgp,
    aa.eancode,
    aa.qrcode,
    aa.valid,
    aa.grp,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase,
    aa.color,
    aa.icon,
    aa.amount
   FROM (iis.tic_art aa
     LEFT JOIN iis.tic_artx aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.tic_artx_v;
       iis          iis    false    851    851    839    839    839    839    839    839    851    839    839    839    839    839    839    839    839    851    8            U           1259    22572    tic_cena    TABLE     �  CREATE TABLE iis.tic_cena (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    text character varying(500) NOT NULL,
    tp numeric(20,0),
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    color character varying(20),
    icon character varying(20),
    CONSTRAINT ckc_tic_cena1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.tic_cena;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_cena    ACL     j   GRANT ALL ON TABLE iis.tic_cena TO PUBLIC;
GRANT ALL ON TABLE iis.tic_cena TO postgres WITH GRANT OPTION;
          iis          iis    false    853            V           1259    22579 
   tic_cenatp    TABLE     0  CREATE TABLE iis.tic_cenatp (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    text character varying(500) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_tic_cenatp1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.tic_cenatp;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_cenatp    ACL     n   GRANT ALL ON TABLE iis.tic_cenatp TO PUBLIC;
GRANT ALL ON TABLE iis.tic_cenatp TO postgres WITH GRANT OPTION;
          iis          iis    false    854            W           1259    22586    tic_cenatpx    TABLE     �   CREATE TABLE iis.tic_cenatpx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.tic_cenatpx;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_cenatpx    ACL     p   GRANT ALL ON TABLE iis.tic_cenatpx TO PUBLIC;
GRANT ALL ON TABLE iis.tic_cenatpx TO postgres WITH GRANT OPTION;
          iis          iis    false    855            X           1259    22592    tic_cenatpx_v    VIEW     '  CREATE VIEW iis.tic_cenatpx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.tic_cenatp aa
     LEFT JOIN iis.tic_cenatpx aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.tic_cenatpx_v;
       iis          iis    false    854    854    854    854    854    855    855    855    855    8            �!           0    0    TABLE tic_cenatpx_v    ACL     t   GRANT ALL ON TABLE iis.tic_cenatpx_v TO PUBLIC;
GRANT ALL ON TABLE iis.tic_cenatpx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    856            Y           1259    22596 	   tic_cenax    TABLE     �   CREATE TABLE iis.tic_cenax (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.tic_cenax;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_cenax    ACL     l   GRANT ALL ON TABLE iis.tic_cenax TO PUBLIC;
GRANT ALL ON TABLE iis.tic_cenax TO postgres WITH GRANT OPTION;
          iis          iis    false    857            Z           1259    22602    tic_cenax_v    VIEW     G  CREATE VIEW iis.tic_cenax_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.tp,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase,
    aa.color,
    aa.icon
   FROM (iis.tic_cena aa
     LEFT JOIN iis.tic_cenax aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.tic_cenax_v;
       iis          iis    false    853    853    853    853    853    853    853    853    857    857    857    857    8            �!           0    0    TABLE tic_cenax_v    ACL     p   GRANT ALL ON TABLE iis.tic_cenax_v TO PUBLIC;
GRANT ALL ON TABLE iis.tic_cenax_v TO postgres WITH GRANT OPTION;
          iis          iis    false    858            [           1259    22606    tic_chanellseatloc    TABLE        CREATE TABLE iis.tic_chanellseatloc (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    chanell numeric(20,0) NOT NULL,
    seatloc numeric(20,0) NOT NULL,
    count numeric(20,0) NOT NULL,
    begda character varying(10) NOT NULL,
    datumod2 character varying(10) NOT NULL
);
 #   DROP TABLE iis.tic_chanellseatloc;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_chanellseatloc    ACL     ~   GRANT ALL ON TABLE iis.tic_chanellseatloc TO PUBLIC;
GRANT ALL ON TABLE iis.tic_chanellseatloc TO postgres WITH GRANT OPTION;
          iis          iis    false    859            \           1259    22609    tic_channel    TABLE     2  CREATE TABLE iis.tic_channel (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    text character varying(500) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_tic_channel1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.tic_channel;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_channel    ACL     p   GRANT ALL ON TABLE iis.tic_channel TO PUBLIC;
GRANT ALL ON TABLE iis.tic_channel TO postgres WITH GRANT OPTION;
          iis          iis    false    860            ]           1259    22616    tic_channeleventpar    TABLE     �   CREATE TABLE iis.tic_channeleventpar (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    channel numeric(20,0) NOT NULL,
    event numeric(20,0) NOT NULL,
    par numeric(20,0)
);
 $   DROP TABLE iis.tic_channeleventpar;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_channeleventpar    COMMENT     r   COMMENT ON TABLE iis.tic_channeleventpar IS 'Veza izmedju objekata
partner - sezonski dogadaj
partner - kanal';
          iis          iis    false    861            �!           0    0    TABLE tic_channeleventpar    ACL     �   GRANT ALL ON TABLE iis.tic_channeleventpar TO PUBLIC;
GRANT ALL ON TABLE iis.tic_channeleventpar TO postgres WITH GRANT OPTION;
          iis          iis    false    861            ^           1259    22619    tic_channelx    TABLE        CREATE TABLE iis.tic_channelx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.tic_channelx;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_channelx    ACL     r   GRANT ALL ON TABLE iis.tic_channelx TO PUBLIC;
GRANT ALL ON TABLE iis.tic_channelx TO postgres WITH GRANT OPTION;
          iis          iis    false    862            _           1259    22625 
   tic_condtp    TABLE     0  CREATE TABLE iis.tic_condtp (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    text character varying(500) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_tic_condtp1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.tic_condtp;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_condtp    COMMENT     �   COMMENT ON TABLE iis.tic_condtp IS 'Uslov ya primenu privilegije koja moye biti povezana sa popustom
vremenskii,  brojni,  iznos
';
          iis          iis    false    863            �!           0    0    TABLE tic_condtp    ACL     n   GRANT ALL ON TABLE iis.tic_condtp TO PUBLIC;
GRANT ALL ON TABLE iis.tic_condtp TO postgres WITH GRANT OPTION;
          iis          iis    false    863            `           1259    22632    tic_condtpx    TABLE     �   CREATE TABLE iis.tic_condtpx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.tic_condtpx;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_condtpx    ACL     p   GRANT ALL ON TABLE iis.tic_condtpx TO PUBLIC;
GRANT ALL ON TABLE iis.tic_condtpx TO postgres WITH GRANT OPTION;
          iis          iis    false    864            a           1259    22638    tic_condtpx_v    VIEW     '  CREATE VIEW iis.tic_condtpx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.tic_condtp aa
     LEFT JOIN iis.tic_condtpx aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.tic_condtpx_v;
       iis          iis    false    863    864    864    864    864    863    863    863    863    8            �!           0    0    TABLE tic_condtpx_v    ACL     t   GRANT ALL ON TABLE iis.tic_condtpx_v TO PUBLIC;
GRANT ALL ON TABLE iis.tic_condtpx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    865            b           1259    22642    tic_discount    TABLE     S  CREATE TABLE iis.tic_discount (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    text character varying(500) NOT NULL,
    tp numeric(20,0) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_tic_discount1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.tic_discount;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_discount    COMMENT     9   COMMENT ON TABLE iis.tic_discount IS 'Popust, staticki';
          iis          iis    false    866            �!           0    0    TABLE tic_discount    ACL     r   GRANT ALL ON TABLE iis.tic_discount TO PUBLIC;
GRANT ALL ON TABLE iis.tic_discount TO postgres WITH GRANT OPTION;
          iis          iis    false    866            c           1259    22649    tic_discounttp    TABLE     8  CREATE TABLE iis.tic_discounttp (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    text character varying(500) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_tic_discounttp1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.tic_discounttp;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_discounttp    COMMENT     6   COMMENT ON TABLE iis.tic_discounttp IS 'Tip popusta';
          iis          iis    false    867            �!           0    0    TABLE tic_discounttp    ACL     v   GRANT ALL ON TABLE iis.tic_discounttp TO PUBLIC;
GRANT ALL ON TABLE iis.tic_discounttp TO postgres WITH GRANT OPTION;
          iis          iis    false    867            d           1259    22656    tic_discounttpx    TABLE       CREATE TABLE iis.tic_discounttpx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
     DROP TABLE iis.tic_discounttpx;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_discounttpx    ACL     x   GRANT ALL ON TABLE iis.tic_discounttpx TO PUBLIC;
GRANT ALL ON TABLE iis.tic_discounttpx TO postgres WITH GRANT OPTION;
          iis          iis    false    868            e           1259    22662    tic_discounttpx_v    VIEW     3  CREATE VIEW iis.tic_discounttpx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.tic_discounttp aa
     LEFT JOIN iis.tic_discounttpx aa2 ON ((aa.id = aa2.tableid)));
 !   DROP VIEW iis.tic_discounttpx_v;
       iis          iis    false    867    868    868    867    867    867    868    868    867    8            �!           0    0    TABLE tic_discounttpx_v    ACL     |   GRANT ALL ON TABLE iis.tic_discounttpx_v TO PUBLIC;
GRANT ALL ON TABLE iis.tic_discounttpx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    869            f           1259    22666    tic_discountx    TABLE       CREATE TABLE iis.tic_discountx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.tic_discountx;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_discountx    ACL     t   GRANT ALL ON TABLE iis.tic_discountx TO PUBLIC;
GRANT ALL ON TABLE iis.tic_discountx TO postgres WITH GRANT OPTION;
          iis          iis    false    870            g           1259    22672    tic_discountx_v    VIEW     8  CREATE VIEW iis.tic_discountx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.tp,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.tic_discount aa
     LEFT JOIN iis.tic_discountx aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.tic_discountx_v;
       iis          iis    false    870    870    866    866    866    866    866    866    870    870    8            �!           0    0    TABLE tic_discountx_v    ACL     x   GRANT ALL ON TABLE iis.tic_discountx_v TO PUBLIC;
GRANT ALL ON TABLE iis.tic_discountx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    871            h           1259    22676    tic_doc    TABLE       CREATE TABLE iis.tic_doc (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    docvr numeric(20,0) NOT NULL,
    date character varying(10) NOT NULL,
    tm character varying(20) NOT NULL,
    curr numeric(20,0),
    currrate numeric(16,5),
    usr numeric(20,0) NOT NULL,
    status character varying(20),
    docobj numeric(20,0),
    broj numeric(20,0),
    obj2 numeric(20,0),
    opis character varying(2000),
    timecreation character varying(20),
    storno numeric(1,0) DEFAULT 0 NOT NULL,
    year numeric(4,0) NOT NULL
);
    DROP TABLE iis.tic_doc;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_doc    ACL     h   GRANT ALL ON TABLE iis.tic_doc TO PUBLIC;
GRANT ALL ON TABLE iis.tic_doc TO postgres WITH GRANT OPTION;
          iis          iis    false    872            i           1259    22682    tic_docb    TABLE     �   CREATE TABLE iis.tic_docb (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    doc numeric(20,0) NOT NULL,
    tp character varying(2) NOT NULL,
    bcontent bytea NOT NULL
);
    DROP TABLE iis.tic_docb;
       iis         heap    iis    false    8            j           1259    22687    tic_docdelivery    TABLE     �  CREATE TABLE iis.tic_docdelivery (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    doc numeric(20,0) NOT NULL,
    courier numeric(20,0),
    adress character varying(1000) NOT NULL,
    amount numeric(16,2),
    dat character varying(10) NOT NULL,
    datdelivery character varying(10),
    status character varying(1) NOT NULL,
    note character varying(4000),
    parent numeric(20,0),
    country character(10),
    zip character(10),
    city character(10)
);
     DROP TABLE iis.tic_docdelivery;
       iis         heap    postgres    false    8            �!           0    0    TABLE tic_docdelivery    COMMENT     j   COMMENT ON TABLE iis.tic_docdelivery IS '   ** status 0 priprema, 1 transpoer, 2 isporuceno, 3 odbijeno';
          iis          postgres    false    874            k           1259    22692    tic_docdocslink    TABLE     �   CREATE TABLE iis.tic_docdocslink (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    doc numeric(20,0) NOT NULL,
    docs numeric(20,0) NOT NULL
);
     DROP TABLE iis.tic_docdocslink;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_docdocslink    ACL     x   GRANT ALL ON TABLE iis.tic_docdocslink TO PUBLIC;
GRANT ALL ON TABLE iis.tic_docdocslink TO postgres WITH GRANT OPTION;
          iis          iis    false    875            l           1259    22695    tic_doclink    TABLE     �   CREATE TABLE iis.tic_doclink (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    doc1 numeric(20,0) NOT NULL,
    doc2 numeric(20,0) NOT NULL,
    "time" date NOT NULL
);
    DROP TABLE iis.tic_doclink;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_doclink    COMMENT     F   COMMENT ON TABLE iis.tic_doclink IS 'Reyervacije mogu biti povezane';
          iis          iis    false    876            �!           0    0    TABLE tic_doclink    ACL     p   GRANT ALL ON TABLE iis.tic_doclink TO PUBLIC;
GRANT ALL ON TABLE iis.tic_doclink TO postgres WITH GRANT OPTION;
          iis          iis    false    876            m           1259    22698    tic_docpayment    TABLE     �   CREATE TABLE iis.tic_docpayment (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    doc numeric(20,0) NOT NULL,
    paymenttp numeric(20,0) NOT NULL,
    amount numeric(16,2) NOT NULL,
    bcontent bytea,
    ccard numeric(20,0)
);
    DROP TABLE iis.tic_docpayment;
       iis         heap    iis    false    8            n           1259    22703    tic_docs    TABLE       CREATE TABLE iis.tic_docs (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    doc numeric(20,0),
    event numeric(20,0) NOT NULL,
    loc numeric(20,0) NOT NULL,
    art numeric(20,0),
    tgp numeric(20,0),
    taxrate numeric(16,5),
    price numeric(16,5),
    input numeric(16,5),
    output numeric(16,5),
    discount numeric(16,5),
    curr numeric(20,0),
    currrate numeric(16,5),
    duguje numeric(16,5),
    potrazuje numeric(16,5),
    leftcurr numeric(16,5),
    rightcurr numeric(16,5),
    begtm character varying(20),
    endtm character varying(20),
    status character varying(20),
    fee numeric(16,5),
    par numeric(20,0),
    descript character varying(2000),
    cena numeric(20,0),
    reztm character varying(10),
    storno character varying DEFAULT 0
);
    DROP TABLE iis.tic_docs;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_docs    ACL     j   GRANT ALL ON TABLE iis.tic_docs TO PUBLIC;
GRANT ALL ON TABLE iis.tic_docs TO postgres WITH GRANT OPTION;
          iis          iis    false    878            o           1259    22709    tic_docslink    TABLE     �   CREATE TABLE iis.tic_docslink (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    docs1 numeric(20,0),
    docs2 numeric(20,0),
    "time" date
);
    DROP TABLE iis.tic_docslink;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_docslink    ACL     r   GRANT ALL ON TABLE iis.tic_docslink TO PUBLIC;
GRANT ALL ON TABLE iis.tic_docslink TO postgres WITH GRANT OPTION;
          iis          iis    false    879            p           1259    22712    tic_docsuid    TABLE     �  CREATE TABLE iis.tic_docsuid (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    docs numeric(20,0) NOT NULL,
    first character varying(100),
    last character varying(100),
    uid character varying(100),
    pib character varying(100),
    adress character varying(1000),
    city character varying(400),
    zip character varying(10),
    country character varying(400),
    phon character varying(100),
    email character varying(100)
);
    DROP TABLE iis.tic_docsuid;
       iis         heap    postgres    false    8            q           1259    22717    tic_doctpx_v    VIEW     @  CREATE VIEW iis.tic_doctpx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.valid,
    aa.duguje,
    aa.znak,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.tic_doctp aa
     LEFT JOIN iis.tic_doctpx aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.tic_doctpx_v;
       iis          iis    false    741    741    741    741    740    740    740    740    740    740    740    8            �!           0    0    TABLE tic_doctpx_v    ACL     r   GRANT ALL ON TABLE iis.tic_doctpx_v TO PUBLIC;
GRANT ALL ON TABLE iis.tic_doctpx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    881            r           1259    22721 	   tic_docvr    TABLE     M  CREATE TABLE iis.tic_docvr (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    text character varying(500) NOT NULL,
    tp numeric(20,0) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_tic_docvr1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.tic_docvr;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_docvr    COMMENT     �   COMMENT ON TABLE iis.tic_docvr IS 'Vrsta dokumenta
-- ulaz
-- rezervacija
-- rezervacija storno
-- kupovina
-- storno kupovina
-- storno kupovina pojedinacna
-- aktivacija
-- aktivacija sa rezervacijom
I sve to preko web-a';
          iis          iis    false    882            �!           0    0    TABLE tic_docvr    ACL     l   GRANT ALL ON TABLE iis.tic_docvr TO PUBLIC;
GRANT ALL ON TABLE iis.tic_docvr TO postgres WITH GRANT OPTION;
          iis          iis    false    882            s           1259    22728 
   tic_docvrx    TABLE     �   CREATE TABLE iis.tic_docvrx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.tic_docvrx;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_docvrx    ACL     n   GRANT ALL ON TABLE iis.tic_docvrx TO PUBLIC;
GRANT ALL ON TABLE iis.tic_docvrx TO postgres WITH GRANT OPTION;
          iis          iis    false    883            t           1259    22734    tic_docvrx_v    VIEW     /  CREATE VIEW iis.tic_docvrx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.tp,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.tic_docvr aa
     LEFT JOIN iis.tic_docvrx aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.tic_docvrx_v;
       iis          iis    false    883    882    882    882    882    882    882    883    883    883    8            �!           0    0    TABLE tic_docvrx_v    ACL     r   GRANT ALL ON TABLE iis.tic_docvrx_v TO PUBLIC;
GRANT ALL ON TABLE iis.tic_docvrx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    884            u           1259    22738 	   tic_event    TABLE     �  CREATE TABLE iis.tic_event (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    text character varying(500) NOT NULL,
    tp numeric(20,0) NOT NULL,
    begda character varying(10) NOT NULL,
    endda character varying(10) NOT NULL,
    begtm character varying(5),
    endtm character varying(5),
    status numeric(1,0) DEFAULT 1 NOT NULL,
    descript character varying(4000),
    note character varying(4000),
    event numeric(20,0),
    ctg numeric(20,0),
    loc numeric(20,0),
    par numeric(20,0),
    tmp numeric(1,0),
    season numeric(20,0),
    map_extent numeric[],
    map_min_zoom integer,
    map_max_zoom integer,
    map_max_resolution numeric,
    tile_extent numeric[],
    tile_size numeric[],
    venue_id numeric(20,0),
    enable_tiles boolean,
    map_zoom_level numeric,
    have_background boolean,
    background_image character varying(255),
    loc_id numeric(20,0)
);
    DROP TABLE iis.tic_event;
       iis         heap    iis    false    8            �!           0    0    COLUMN tic_event.loc    COMMENT     L   COMMENT ON COLUMN iis.tic_event.loc IS 'Stadio, hala, pozorisna scena ...';
          iis          iis    false    885            �!           0    0    TABLE tic_event    ACL     l   GRANT ALL ON TABLE iis.tic_event TO PUBLIC;
GRANT ALL ON TABLE iis.tic_event TO postgres WITH GRANT OPTION;
          iis          iis    false    885            v           1259    22744    tic_eventagenda    TABLE     �   CREATE TABLE iis.tic_eventagenda (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    event numeric(20,0) NOT NULL,
    agenda numeric(20,0) NOT NULL,
    date character varying(10) NOT NULL
);
     DROP TABLE iis.tic_eventagenda;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_eventagenda    ACL     x   GRANT ALL ON TABLE iis.tic_eventagenda TO PUBLIC;
GRANT ALL ON TABLE iis.tic_eventagenda TO postgres WITH GRANT OPTION;
          iis          iis    false    886            w           1259    22747    tic_eventart    TABLE     �  CREATE TABLE iis.tic_eventart (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    event numeric(20,0) NOT NULL,
    art numeric(20,0) NOT NULL,
    descript character varying(4000),
    begda character varying(10) NOT NULL,
    endda character varying(10) NOT NULL,
    nart character varying(1000),
    discount numeric,
    color character varying(20),
    icon character varying(20)
);
    DROP TABLE iis.tic_eventart;
       iis         heap    iis    false    8            x           1259    22752    tic_eventartcena    TABLE     �  CREATE TABLE iis.tic_eventartcena (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    event numeric(20,0) NOT NULL,
    art numeric(20,0) NOT NULL,
    cena numeric(20,0) NOT NULL,
    value numeric(16,5) NOT NULL,
    terr numeric(20,0) NOT NULL,
    begda character varying(10) NOT NULL,
    endda character varying(10) NOT NULL,
    curr numeric(20,0) NOT NULL,
    eventart numeric(20,0)
);
 !   DROP TABLE iis.tic_eventartcena;
       iis         heap    iis    false    8            y           1259    22755    tic_eventartlink    TABLE     �   CREATE TABLE iis.tic_eventartlink (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    eventart1 numeric(20,0) NOT NULL,
    eventart2 numeric(20,0) NOT NULL,
    tp character varying(2) NOT NULL
);
 !   DROP TABLE iis.tic_eventartlink;
       iis         heap    iis    false    8            z           1259    22758    tic_eventartloc    TABLE       CREATE TABLE iis.tic_eventartloc (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    eventart numeric(20,0) NOT NULL,
    loctp numeric(20,0) NOT NULL,
    loc numeric(20,0) NOT NULL,
    begda character varying(10) NOT NULL,
    endda character varying(10) NOT NULL
);
     DROP TABLE iis.tic_eventartloc;
       iis         heap    iis    false    8            {           1259    22761    tic_eventatt    TABLE     �  CREATE TABLE iis.tic_eventatt (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    text character varying(500) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    inputtp numeric(20,0),
    ddlist character varying(500),
    tp numeric(20,0),
    CONSTRAINT ckc_tic_eventatt1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.tic_eventatt;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_eventatt    ACL     r   GRANT ALL ON TABLE iis.tic_eventatt TO PUBLIC;
GRANT ALL ON TABLE iis.tic_eventatt TO postgres WITH GRANT OPTION;
          iis          iis    false    891            |           1259    22768    tic_eventatts    TABLE     k  CREATE TABLE iis.tic_eventatts (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    event numeric(20,0) NOT NULL,
    att numeric(20,0) NOT NULL,
    value character varying(1000),
    valid numeric(1,0) DEFAULT 0 NOT NULL,
    text character varying(1000),
    color character varying(20),
    icon character(10),
    condition character varying(200)
);
    DROP TABLE iis.tic_eventatts;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_eventatts    ACL     t   GRANT ALL ON TABLE iis.tic_eventatts TO PUBLIC;
GRANT ALL ON TABLE iis.tic_eventatts TO postgres WITH GRANT OPTION;
          iis          iis    false    892            }           1259    22774    tic_eventatttp    TABLE     6  CREATE TABLE iis.tic_eventatttp (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(20) NOT NULL,
    text character varying(60) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_tic_eventatttp1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.tic_eventatttp;
       iis         heap    postgres    false    8            ~           1259    22779    tic_eventatttpx    TABLE       CREATE TABLE iis.tic_eventatttpx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
     DROP TABLE iis.tic_eventatttpx;
       iis         heap    postgres    false    8                       1259    22785    tic_eventatttpx_v    VIEW     3  CREATE VIEW iis.tic_eventatttpx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.tic_eventatttp aa
     LEFT JOIN iis.tic_eventatttpx aa2 ON ((aa.id = aa2.tableid)));
 !   DROP VIEW iis.tic_eventatttpx_v;
       iis          postgres    false    893    894    894    894    894    893    893    893    893    8            �           1259    22789    tic_eventattx    TABLE       CREATE TABLE iis.tic_eventattx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.tic_eventattx;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_eventattx    ACL     t   GRANT ALL ON TABLE iis.tic_eventattx TO PUBLIC;
GRANT ALL ON TABLE iis.tic_eventattx TO postgres WITH GRANT OPTION;
          iis          iis    false    896            �           1259    22795    tic_eventattx_v    VIEW     W  CREATE VIEW iis.tic_eventattx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.tp,
    aa.valid,
    aa.inputtp,
    aa.ddlist,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.tic_eventatt aa
     LEFT JOIN iis.tic_eventattx aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.tic_eventattx_v;
       iis          postgres    false    896    891    896    896    896    891    891    891    891    891    891    891    8            �           1259    22800    tic_eventcenatp    TABLE     �   CREATE TABLE iis.tic_eventcenatp (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    event numeric(20,0) NOT NULL,
    cenatp numeric(20,0) NOT NULL,
    begda character varying(10) NOT NULL,
    endda character varying(10) NOT NULL
);
     DROP TABLE iis.tic_eventcenatp;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_eventcenatp    ACL     x   GRANT ALL ON TABLE iis.tic_eventcenatp TO PUBLIC;
GRANT ALL ON TABLE iis.tic_eventcenatp TO postgres WITH GRANT OPTION;
          iis          iis    false    898            �           1259    22803    tic_eventctg    TABLE     4  CREATE TABLE iis.tic_eventctg (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    text character varying(500) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_tic_eventctg1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.tic_eventctg;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_eventctg    ACL     r   GRANT ALL ON TABLE iis.tic_eventctg TO PUBLIC;
GRANT ALL ON TABLE iis.tic_eventctg TO postgres WITH GRANT OPTION;
          iis          iis    false    899            �           1259    22810    tic_eventctgx    TABLE       CREATE TABLE iis.tic_eventctgx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.tic_eventctgx;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_eventctgx    ACL     t   GRANT ALL ON TABLE iis.tic_eventctgx TO PUBLIC;
GRANT ALL ON TABLE iis.tic_eventctgx TO postgres WITH GRANT OPTION;
          iis          iis    false    900            �           1259    22816    tic_eventctgx_v    VIEW     -  CREATE VIEW iis.tic_eventctgx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.tic_eventctg aa
     LEFT JOIN iis.tic_eventctgx aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.tic_eventctgx_v;
       iis          iis    false    899    900    900    900    900    899    899    899    899    8            �!           0    0    TABLE tic_eventctgx_v    ACL     x   GRANT ALL ON TABLE iis.tic_eventctgx_v TO PUBLIC;
GRANT ALL ON TABLE iis.tic_eventctgx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    901            �           1259    22820    tic_eventlink    TABLE     �   CREATE TABLE iis.tic_eventlink (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    event1 numeric(20,0) NOT NULL,
    event2 numeric(20,0) NOT NULL,
    note character varying(4000) NOT NULL
);
    DROP TABLE iis.tic_eventlink;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_eventlink    COMMENT     `   COMMENT ON TABLE iis.tic_eventlink IS 'Ovde treba obezbediti funkcionalnost
Otkaz
Odloženo';
          iis          iis    false    902            �!           0    0    TABLE tic_eventlink    ACL     t   GRANT ALL ON TABLE iis.tic_eventlink TO PUBLIC;
GRANT ALL ON TABLE iis.tic_eventlink TO postgres WITH GRANT OPTION;
          iis          iis    false    902            �           1259    22825    tic_eventloc    TABLE     0  CREATE TABLE iis.tic_eventloc (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    event numeric(20,0) NOT NULL,
    loc numeric(20,0) NOT NULL,
    begda character varying(10) NOT NULL,
    endda character varying(10) NOT NULL,
    color character varying(20),
    icon character varying(20)
);
    DROP TABLE iis.tic_eventloc;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_eventloc    ACL     r   GRANT ALL ON TABLE iis.tic_eventloc TO PUBLIC;
GRANT ALL ON TABLE iis.tic_eventloc TO postgres WITH GRANT OPTION;
          iis          iis    false    903            �           1259    22828    tic_eventobj    TABLE     �  CREATE TABLE iis.tic_eventobj (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    event numeric(20,0) NOT NULL,
    objtp numeric(20,0) NOT NULL,
    obj numeric(20,0) NOT NULL,
    begda character varying(10) NOT NULL,
    endda character varying(10) NOT NULL,
    begtm character varying(5),
    endtm character varying(5),
    color character varying(20),
    icon character varying(20)
);
    DROP TABLE iis.tic_eventobj;
       iis         heap    iis    false    8            �           1259    22831 
   tic_events    TABLE     �  CREATE TABLE iis.tic_events (
    id numeric(20,0) NOT NULL,
    selection_duration character varying(5),
    payment_duration character varying(5),
    booking_duration character varying(5),
    max_ticket numeric(1,0),
    online_payment numeric(1,0),
    cash_payment numeric(1,0),
    delivery_payment numeric(1,0),
    presale_enabled numeric(1,0),
    presale_until character varying(10),
    presale_discount numeric(5,2),
    presale_discount_absolute numeric(5,2)
);
    DROP TABLE iis.tic_events;
       iis         heap    iis    false    8            �!           0    0 $   COLUMN tic_events.selection_duration    COMMENT     ]   COMMENT ON COLUMN iis.tic_events.selection_duration IS 'Trajanje selekcije, odabira karata';
          iis          iis    false    905            �!           0    0 "   COLUMN tic_events.payment_duration    COMMENT     e   COMMENT ON COLUMN iis.tic_events.payment_duration IS 'Trajanje procesa placanja selektovanih karti';
          iis          iis    false    905            �!           0    0 "   COLUMN tic_events.booking_duration    COMMENT     �   COMMENT ON COLUMN iis.tic_events.booking_duration IS 'Trajanje rezervacije karti. Ova reyervacija moze biti dodatno naplacena';
          iis          iis    false    905            �!           0    0    COLUMN tic_events.max_ticket    COMMENT     e   COMMENT ON COLUMN iis.tic_events.max_ticket IS 'Maksimalan broj karti koje jedan kupac moze kupiti';
          iis          iis    false    905            �!           0    0     COLUMN tic_events.online_payment    COMMENT     M   COMMENT ON COLUMN iis.tic_events.online_payment IS 'Mogu''e online plcanje';
          iis          iis    false    905            �!           0    0    COLUMN tic_events.cash_payment    COMMENT     J   COMMENT ON COLUMN iis.tic_events.cash_payment IS 'Moguce placanje kesom';
          iis          iis    false    905            �!           0    0 !   COLUMN tic_events.presale_enabled    COMMENT     J   COMMENT ON COLUMN iis.tic_events.presale_enabled IS 'Moguca predprodaja';
          iis          iis    false    905            �!           0    0    TABLE tic_events    ACL     n   GRANT ALL ON TABLE iis.tic_events TO PUBLIC;
GRANT ALL ON TABLE iis.tic_events TO postgres WITH GRANT OPTION;
          iis          iis    false    905            �           1259    22834    tic_eventst    TABLE     Y  CREATE TABLE iis.tic_eventst (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    loc1 numeric(20,0) NOT NULL,
    code1 character varying(100) NOT NULL,
    text1 character varying(500) NOT NULL,
    ntp1 character varying(4000),
    loc2 numeric(20,0),
    code2 character varying(100),
    text2 character varying(500),
    ntp2 character varying(4000),
    event numeric(20,0) NOT NULL,
    graftp numeric(20,0),
    latlongs character varying(4000),
    radius numeric(15,5),
    color character varying(100),
    fillcolor character varying(100),
    originfillcolor character varying(100),
    rownum character varying(100),
    art numeric(20,0),
    cart character varying(1000),
    nart character varying(4000),
    longtext character varying(4000),
    tp1 numeric(20,0),
    tp2 numeric(20,0),
    kol numeric(10,0),
    status text
);
    DROP TABLE iis.tic_eventst;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_eventst    COMMENT     ;   COMMENT ON TABLE iis.tic_eventst IS 'Setovanje dogadjaja';
          iis          iis    false    906            �!           0    0    COLUMN tic_eventst.id    COMMENT     7   COMMENT ON COLUMN iis.tic_eventst.id IS 'Kod sedista';
          iis          iis    false    906            �!           0    0    COLUMN tic_eventst.code1    COMMENT     D   COMMENT ON COLUMN iis.tic_eventst.code1 IS 'Kod lokacije, sedista';
          iis          iis    false    906            �!           0    0    COLUMN tic_eventst.text1    COMMENT     }   COMMENT ON COLUMN iis.tic_eventst.text1 IS 'Naziv sedista, verovatno za sedista uzima  ima istu vrednost sa atributom CODE';
          iis          iis    false    906            �!           0    0    COLUMN tic_eventst.ntp1    COMMENT     �   COMMENT ON COLUMN iis.tic_eventst.ntp1 IS 'Tip sedista da znas da li je sektor ili sediste. Mozda i ne treba jer su za prodaju bitna samo sedista.';
          iis          iis    false    906            �!           0    0    COLUMN tic_eventst.loc2    COMMENT     Z   COMMENT ON COLUMN iis.tic_eventst.loc2 IS 'Nadredjena lokacija sektor, mozda i ne treba';
          iis          iis    false    906            �!           0    0    COLUMN tic_eventst.code2    COMMENT     G   COMMENT ON COLUMN iis.tic_eventst.code2 IS 'Kod nadredjene lokacije ';
          iis          iis    false    906            �!           0    0    COLUMN tic_eventst.text2    COMMENT     E   COMMENT ON COLUMN iis.tic_eventst.text2 IS 'Isto kao i za lokaciju';
          iis          iis    false    906            �!           0    0    COLUMN tic_eventst.event    COMMENT     7   COMMENT ON COLUMN iis.tic_eventst.event IS 'Dogadjaj';
          iis          iis    false    906            �!           0    0    COLUMN tic_eventst.art    COMMENT     6   COMMENT ON COLUMN iis.tic_eventst.art IS 'Artikal, ';
          iis          iis    false    906            �!           0    0    COLUMN tic_eventst.nart    COMMENT     ;   COMMENT ON COLUMN iis.tic_eventst.nart IS 'Naziv artikla';
          iis          iis    false    906            �           1259    22839    tic_eventtp    TABLE     2  CREATE TABLE iis.tic_eventtp (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    text character varying(500) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_tic_eventtp1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.tic_eventtp;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_eventtp    ACL     p   GRANT ALL ON TABLE iis.tic_eventtp TO PUBLIC;
GRANT ALL ON TABLE iis.tic_eventtp TO postgres WITH GRANT OPTION;
          iis          iis    false    907            �           1259    22846    tic_eventtps    TABLE       CREATE TABLE iis.tic_eventtps (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    eventtp numeric(20,0) NOT NULL,
    att numeric(20,0) NOT NULL,
    value character varying(1000),
    begda character varying(10) NOT NULL,
    endda character varying(10) NOT NULL
);
    DROP TABLE iis.tic_eventtps;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_eventtps    ACL     r   GRANT ALL ON TABLE iis.tic_eventtps TO PUBLIC;
GRANT ALL ON TABLE iis.tic_eventtps TO postgres WITH GRANT OPTION;
          iis          iis    false    908            �           1259    22851    tic_eventtpx    TABLE        CREATE TABLE iis.tic_eventtpx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.tic_eventtpx;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_eventtpx    ACL     r   GRANT ALL ON TABLE iis.tic_eventtpx TO PUBLIC;
GRANT ALL ON TABLE iis.tic_eventtpx TO postgres WITH GRANT OPTION;
          iis          iis    false    909            �           1259    22857    tic_eventtpx_v    VIEW     *  CREATE VIEW iis.tic_eventtpx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.tic_eventtp aa
     LEFT JOIN iis.tic_eventtpx aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.tic_eventtpx_v;
       iis          iis    false    907    907    909    909    909    909    907    907    907    8            �!           0    0    TABLE tic_eventtpx_v    ACL     v   GRANT ALL ON TABLE iis.tic_eventtpx_v TO PUBLIC;
GRANT ALL ON TABLE iis.tic_eventtpx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    910            �           1259    22861 
   tic_eventx    TABLE     �   CREATE TABLE iis.tic_eventx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.tic_eventx;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_eventx    ACL     n   GRANT ALL ON TABLE iis.tic_eventx TO PUBLIC;
GRANT ALL ON TABLE iis.tic_eventx TO postgres WITH GRANT OPTION;
          iis          iis    false    911            �           1259    22867    tic_eventx_v    VIEW     �  CREATE VIEW iis.tic_eventx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.tp,
    aa.begda,
    aa.endda,
    aa.begtm,
    aa.endtm,
    aa.status,
    aa.descript,
    aa.note,
    aa.event,
    aa.ctg,
    aa.loc,
    aa.par,
    aa.tmp,
    aa.season,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.tic_event aa
     LEFT JOIN iis.tic_eventx aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.tic_eventx_v;
       iis          postgres    false    885    885    885    885    885    885    885    885    885    885    885    885    885    885    885    911    911    911    911    885    885    885    8            �           1259    22872    tic_parprivilege    TABLE     +  CREATE TABLE iis.tic_parprivilege (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    par numeric(20,0) NOT NULL,
    privilege numeric(20,0) NOT NULL,
    begda character varying(10) NOT NULL,
    endda character varying(10) NOT NULL,
    maxprc numeric(15,2),
    maxval numeric(15,2)
);
 !   DROP TABLE iis.tic_parprivilege;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_parprivilege    ACL     z   GRANT ALL ON TABLE iis.tic_parprivilege TO PUBLIC;
GRANT ALL ON TABLE iis.tic_parprivilege TO postgres WITH GRANT OPTION;
          iis          iis    false    913            �           1259    22875    tic_paycard    TABLE     i  CREATE TABLE iis.tic_paycard (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    docpayment numeric(20,0) NOT NULL,
    ccard numeric(20,0) NOT NULL,
    owner character varying(200),
    cardnum character varying(20),
    code character varying(4),
    dat character varying(10),
    amount numeric(16,2) NOT NULL,
    status numeric(1,0) NOT NULL
);
    DROP TABLE iis.tic_paycard;
       iis         heap    iis    false    8            �           1259    22878    tic_privilege    TABLE     |  CREATE TABLE iis.tic_privilege (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    text character varying(500) NOT NULL,
    tp numeric(20,0) NOT NULL,
    limitirano numeric(1,0) DEFAULT 1,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_tic_privilege1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.tic_privilege;
       iis         heap    iis    false    8            �!           0    0    COLUMN tic_privilege.limitirano    COMMENT     P   COMMENT ON COLUMN iis.tic_privilege.limitirano IS 'Da li se primenjuju limiti';
          iis          iis    false    915            �!           0    0    TABLE tic_privilege    ACL     t   GRANT ALL ON TABLE iis.tic_privilege TO PUBLIC;
GRANT ALL ON TABLE iis.tic_privilege TO postgres WITH GRANT OPTION;
          iis          iis    false    915            �           1259    22886    tic_privilegecond    TABLE     �  CREATE TABLE iis.tic_privilegecond (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    privilege numeric(20,0) NOT NULL,
    begcondtp numeric(20,0) NOT NULL,
    begcondition character varying(20) NOT NULL,
    begvalue character varying(20) NOT NULL,
    endcondtp numeric(20,0),
    endcondition character varying(20),
    endvalue character varying(20),
    begda character varying(10) NOT NULL,
    endda character varying(10) NOT NULL
);
 "   DROP TABLE iis.tic_privilegecond;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_privilegecond    COMMENT     �   COMMENT ON TABLE iis.tic_privilegecond IS 'Uslov ya primenu privilegije
Na osnovu tipa uslova 
da li je > vremenskii, > brojni,  < ili > iznos
koliko
i do koliko vazi
da li je > vremenskii, > brojni,  < ili > iznos
koliko
';
          iis          iis    false    916            �!           0    0    TABLE tic_privilegecond    ACL     |   GRANT ALL ON TABLE iis.tic_privilegecond TO PUBLIC;
GRANT ALL ON TABLE iis.tic_privilegecond TO postgres WITH GRANT OPTION;
          iis          iis    false    916            �           1259    22889    tic_privilegediscount    TABLE     #  CREATE TABLE iis.tic_privilegediscount (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    privilege numeric(20,0) NOT NULL,
    discount numeric(20,0) NOT NULL,
    value numeric(15,2) NOT NULL,
    begda character varying(10) NOT NULL,
    endda character varying(10) NOT NULL
);
 &   DROP TABLE iis.tic_privilegediscount;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_privilegediscount    COMMENT     R   COMMENT ON TABLE iis.tic_privilegediscount IS 'Popust vezan za neku privilegiju';
          iis          iis    false    917            �!           0    0    TABLE tic_privilegediscount    ACL     �   GRANT ALL ON TABLE iis.tic_privilegediscount TO PUBLIC;
GRANT ALL ON TABLE iis.tic_privilegediscount TO postgres WITH GRANT OPTION;
          iis          iis    false    917            �           1259    22892    tic_privilegelink    TABLE        CREATE TABLE iis.tic_privilegelink (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    privilege1 numeric(20,0) NOT NULL,
    privilege2 numeric(20,0) NOT NULL,
    begda character varying(10) NOT NULL,
    endda character varying(10) NOT NULL
);
 "   DROP TABLE iis.tic_privilegelink;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_privilegelink    ACL     |   GRANT ALL ON TABLE iis.tic_privilegelink TO PUBLIC;
GRANT ALL ON TABLE iis.tic_privilegelink TO postgres WITH GRANT OPTION;
          iis          iis    false    918            �           1259    22895    tic_privilegetp    TABLE     :  CREATE TABLE iis.tic_privilegetp (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    text character varying(500) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_tic_privilegetp1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
     DROP TABLE iis.tic_privilegetp;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_privilegetp    ACL     x   GRANT ALL ON TABLE iis.tic_privilegetp TO PUBLIC;
GRANT ALL ON TABLE iis.tic_privilegetp TO postgres WITH GRANT OPTION;
          iis          iis    false    919            �           1259    22902    tic_privilegetpx    TABLE       CREATE TABLE iis.tic_privilegetpx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
 !   DROP TABLE iis.tic_privilegetpx;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_privilegetpx    ACL     z   GRANT ALL ON TABLE iis.tic_privilegetpx TO PUBLIC;
GRANT ALL ON TABLE iis.tic_privilegetpx TO postgres WITH GRANT OPTION;
          iis          iis    false    920            �           1259    22908    tic_privilegetpx_v    VIEW     6  CREATE VIEW iis.tic_privilegetpx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.tic_privilegetp aa
     LEFT JOIN iis.tic_privilegetpx aa2 ON ((aa.id = aa2.tableid)));
 "   DROP VIEW iis.tic_privilegetpx_v;
       iis          iis    false    919    919    919    919    919    920    920    920    920    8            �!           0    0    TABLE tic_privilegetpx_v    ACL     ~   GRANT ALL ON TABLE iis.tic_privilegetpx_v TO PUBLIC;
GRANT ALL ON TABLE iis.tic_privilegetpx_v TO postgres WITH GRANT OPTION;
          iis          iis    false    921            �           1259    22912    tic_privilegex    TABLE       CREATE TABLE iis.tic_privilegex (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.tic_privilegex;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_privilegex    ACL     v   GRANT ALL ON TABLE iis.tic_privilegex TO PUBLIC;
GRANT ALL ON TABLE iis.tic_privilegex TO postgres WITH GRANT OPTION;
          iis          iis    false    922            �           1259    22918    tic_privilegex_v    VIEW     N  CREATE VIEW iis.tic_privilegex_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.tp,
    aa.limitirano,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.tic_privilege aa
     LEFT JOIN iis.tic_privilegex aa2 ON ((aa.id = aa2.tableid)));
     DROP VIEW iis.tic_privilegex_v;
       iis          iis    false    915    915    915    915    915    915    915    922    922    922    922    8            �!           0    0    TABLE tic_privilegex_v    ACL     z   GRANT ALL ON TABLE iis.tic_privilegex_v TO PUBLIC;
GRANT ALL ON TABLE iis.tic_privilegex_v TO postgres WITH GRANT OPTION;
          iis          iis    false    923            �           1259    22922 
   tic_season    TABLE     .  CREATE TABLE iis.tic_season (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    text character varying(500) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_tic_cena1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.tic_season;
       iis         heap    iis    false    8            �           1259    22929    tic_seasonx    TABLE     �   CREATE TABLE iis.tic_seasonx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.tic_seasonx;
       iis         heap    iis    false    8            �           1259    22935    tic_seasonx_v    VIEW     '  CREATE VIEW iis.tic_seasonx_v AS
 SELECT aa.id,
    aa.site,
    aa.code,
    COALESCE(aa2.text, aa.text) AS text,
    aa.valid,
    COALESCE(aa2.lang, 'en'::character varying) AS lang,
    aa2.grammcase
   FROM (iis.tic_season aa
     LEFT JOIN iis.tic_seasonx aa2 ON ((aa.id = aa2.tableid)));
    DROP VIEW iis.tic_seasonx_v;
       iis          iis    false    924    924    924    924    924    925    925    925    925    8            �           1259    22939    tic_seat    TABLE     J  CREATE TABLE iis.tic_seat (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    text character varying(500) NOT NULL,
    tp numeric(20,0) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_cmn_loc1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.tic_seat;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_seat    COMMENT     �   COMMENT ON TABLE iis.tic_seat IS 'Konkretno sediste ili pozicija
Mora imati svoj ID
Grupa sedista ako je parter, onda je kolicina veca od jedan';
          iis          iis    false    927            �!           0    0    TABLE tic_seat    ACL     j   GRANT ALL ON TABLE iis.tic_seat TO PUBLIC;
GRANT ALL ON TABLE iis.tic_seat TO postgres WITH GRANT OPTION;
          iis          iis    false    927            �           1259    22946    tic_seatloc    TABLE       CREATE TABLE iis.tic_seatloc (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    loc numeric(20,0) NOT NULL,
    seat numeric(20,0) NOT NULL,
    count character varying(500) NOT NULL,
    begda character varying(10) NOT NULL,
    endda character varying(10) NOT NULL
);
    DROP TABLE iis.tic_seatloc;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_seatloc    COMMENT     �   COMMENT ON TABLE iis.tic_seatloc IS 'Ovde treba napraviti funkcionalnost
-- pojedinacnog unosa sedišta za iyabranu lokaciju što je difoltna vrednost
-- ya iyabranu lokaviju unesi sva sedista.';
          iis          iis    false    928            �!           0    0    TABLE tic_seatloc    ACL     p   GRANT ALL ON TABLE iis.tic_seatloc TO PUBLIC;
GRANT ALL ON TABLE iis.tic_seatloc TO postgres WITH GRANT OPTION;
          iis          iis    false    928            �           1259    22951 
   tic_seattp    TABLE     0  CREATE TABLE iis.tic_seattp (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    text character varying(500) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_cmn_seattp1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.tic_seattp;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_seattp    COMMENT     k   COMMENT ON TABLE iis.tic_seattp IS 'tip stolice,
tapacirana, 
sklapanje,
fiksna,
montazna,
stajanje';
          iis          iis    false    929            �!           0    0    TABLE tic_seattp    ACL     n   GRANT ALL ON TABLE iis.tic_seattp TO PUBLIC;
GRANT ALL ON TABLE iis.tic_seattp TO postgres WITH GRANT OPTION;
          iis          iis    false    929            �           1259    22958    tic_seattpatt    TABLE     6  CREATE TABLE iis.tic_seattpatt (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    text character varying(500) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_cmn_seattpatt1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.tic_seattpatt;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_seattpatt    ACL     t   GRANT ALL ON TABLE iis.tic_seattpatt TO PUBLIC;
GRANT ALL ON TABLE iis.tic_seattpatt TO postgres WITH GRANT OPTION;
          iis          iis    false    930            �           1259    22965    tic_seattpatts    TABLE       CREATE TABLE iis.tic_seattpatts (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    seattp numeric(20,0) NOT NULL,
    att numeric(20,0) NOT NULL,
    value character varying(500) NOT NULL,
    begda character varying(10) NOT NULL,
    endda character varying(10) NOT NULL
);
    DROP TABLE iis.tic_seattpatts;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_seattpatts    ACL     v   GRANT ALL ON TABLE iis.tic_seattpatts TO PUBLIC;
GRANT ALL ON TABLE iis.tic_seattpatts TO postgres WITH GRANT OPTION;
          iis          iis    false    931            �           1259    22970    tic_seattpattx    TABLE       CREATE TABLE iis.tic_seattpattx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.tic_seattpattx;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_seattpattx    ACL     v   GRANT ALL ON TABLE iis.tic_seattpattx TO PUBLIC;
GRANT ALL ON TABLE iis.tic_seattpattx TO postgres WITH GRANT OPTION;
          iis          iis    false    932            �           1259    22976    tic_seattpx    TABLE     �   CREATE TABLE iis.tic_seattpx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.tic_seattpx;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_seattpx    ACL     p   GRANT ALL ON TABLE iis.tic_seattpx TO PUBLIC;
GRANT ALL ON TABLE iis.tic_seattpx TO postgres WITH GRANT OPTION;
          iis          iis    false    933            �           1259    22982 	   tic_seatx    TABLE     �   CREATE TABLE iis.tic_seatx (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    tableid numeric(20,0) NOT NULL,
    lang character varying(10) NOT NULL,
    grammcase numeric(5,0) DEFAULT 1 NOT NULL,
    text character varying(4000) NOT NULL
);
    DROP TABLE iis.tic_seatx;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_seatx    ACL     l   GRANT ALL ON TABLE iis.tic_seatx TO PUBLIC;
GRANT ALL ON TABLE iis.tic_seatx TO postgres WITH GRANT OPTION;
          iis          iis    false    934            �           1259    22988    tic_speccheck    TABLE     +  CREATE TABLE iis.tic_speccheck (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    docpayment numeric(20,0) NOT NULL,
    bank numeric(20,0) NOT NULL,
    code1 character varying(200),
    code2 character varying(200),
    code3 character varying(200),
    amount numeric(16,2) NOT NULL
);
    DROP TABLE iis.tic_speccheck;
       iis         heap    iis    false    8            �           1259    22993 
   tic_stampa    TABLE     �   CREATE TABLE iis.tic_stampa (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    docs numeric(20,0) NOT NULL,
    "time" character varying(20),
    bcontent bytea,
    status character varying(1),
    tp character varying(1)
);
    DROP TABLE iis.tic_stampa;
       iis         heap    iis    false    8            �!           0    0    TABLE tic_stampa    ACL     n   GRANT ALL ON TABLE iis.tic_stampa TO PUBLIC;
GRANT ALL ON TABLE iis.tic_stampa TO postgres WITH GRANT OPTION;
          iis          iis    false    936            �           1259    22998    tic_table_id_seq    SEQUENCE     �   CREATE SEQUENCE iis.tic_table_id_seq
    START WITH 5000000000000000000
    INCREMENT BY 1
    MINVALUE 5000000000000000000
    NO MAXVALUE
    CACHE 5;
 $   DROP SEQUENCE iis.tic_table_id_seq;
       iis          iis    false    8            �           1259    22999    tic_ticketst    TABLE     �   CREATE TABLE iis.tic_ticketst (
    id numeric(20,0) NOT NULL,
    data jsonb,
    eventid numeric(20,0),
    articleid numeric(20,0),
    tickettype character varying(255),
    width integer,
    height integer
);
    DROP TABLE iis.tic_ticketst;
       iis         heap    postgres    false    8            �           1259    23004    tic_user_messages    TABLE     �   CREATE TABLE iis.tic_user_messages (
    id numeric(20,0) NOT NULL,
    userid numeric(20,0),
    message_text text,
    message_read boolean
);
 "   DROP TABLE iis.tic_user_messages;
       iis         heap    postgres    false    8            �           1259    23009    tic_user_ticket    TABLE       CREATE TABLE iis.tic_user_ticket (
    id numeric(20,0) NOT NULL,
    data jsonb,
    eventid numeric(20,0),
    articleid numeric(20,0),
    tickettype character varying(255),
    userid numeric(20,0),
    seatid numeric(20,0),
    width integer,
    height integer
);
     DROP TABLE iis.tic_user_ticket;
       iis         heap    postgres    false    8            �           1259    23014 	   tic_venue    TABLE     N  CREATE TABLE iis.tic_venue (
    venue_id numeric(20,0) NOT NULL,
    venue_name character varying(255) NOT NULL,
    venue_type character varying(50) NOT NULL,
    map_extent numeric[] NOT NULL,
    map_min_zoom integer NOT NULL,
    map_max_zoom integer NOT NULL,
    map_max_resolution numeric NOT NULL,
    tile_extent numeric[] NOT NULL,
    tile_size numeric[] NOT NULL,
    loc_id numeric(20,0),
    enable_tiles boolean,
    map_zoom_level numeric,
    have_background boolean,
    background_image character varying(255),
    site numeric(20,0),
    code character varying(255)
);
    DROP TABLE iis.tic_venue;
       iis         heap    iis    false    8             "           0    0    TABLE tic_venue    ACL     �   REVOKE ALL ON TABLE iis.tic_venue FROM iis;
GRANT ALL ON TABLE iis.tic_venue TO iis WITH GRANT OPTION;
GRANT ALL ON TABLE iis.tic_venue TO postgres WITH GRANT OPTION;
          iis          iis    false    941            �           1259    23019    tic_venue_item    TABLE     :  CREATE TABLE iis.tic_venue_item (
    id numeric(20,0) NOT NULL,
    type character varying(50) NOT NULL,
    location jsonb,
    radius integer,
    venue character varying(50),
    venue_id numeric(20,0),
    sector character varying(50),
    row_num character varying(50),
    seat_num character varying(50)
);
    DROP TABLE iis.tic_venue_item;
       iis         heap    iis    false    8            �           1259    23024    tmp_cmn_loc    TABLE     o  CREATE TABLE iis.tmp_cmn_loc (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    text character varying(500) NOT NULL,
    long character varying(4000),
    tp numeric(20,0) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_cmn_loc1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.tmp_cmn_loc;
       iis         heap    iis    false    8            "           0    0    TABLE tmp_cmn_loc    COMMENT     B   COMMENT ON TABLE iis.tmp_cmn_loc IS 'Lokacije,  na teritorijama';
          iis          iis    false    943            "           0    0    TABLE tmp_cmn_loc    ACL     p   GRANT ALL ON TABLE iis.tmp_cmn_loc TO PUBLIC;
GRANT ALL ON TABLE iis.tmp_cmn_loc TO postgres WITH GRANT OPTION;
          iis          iis    false    943            �           1259    23031    tmp_cmn_loctp    TABLE     2  CREATE TABLE iis.tmp_cmn_loctp (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    code character varying(100) NOT NULL,
    text character varying(500) NOT NULL,
    valid numeric(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT ckc_cmn_loctp1 CHECK ((valid = ANY (ARRAY[(1)::numeric, (0)::numeric])))
);
    DROP TABLE iis.tmp_cmn_loctp;
       iis         heap    iis    false    8            "           0    0    TABLE tmp_cmn_loctp    COMMENT     �   COMMENT ON TABLE iis.tmp_cmn_loctp IS 'VENUE
-- SCENA
-- ulaz
-- -- BLOK
Nisu izdvojeni posebno kako bi moglo da se kontroliše pravo na rad sa odredenim blokovima';
          iis          iis    false    944            "           0    0    TABLE tmp_cmn_loctp    ACL     t   GRANT ALL ON TABLE iis.tmp_cmn_loctp TO PUBLIC;
GRANT ALL ON TABLE iis.tmp_cmn_loctp TO postgres WITH GRANT OPTION;
          iis          iis    false    944            �           1259    23038    tmp_tic_doc    TABLE     �  CREATE TABLE iis.tmp_tic_doc (
    id numeric(20,0) NOT NULL,
    site numeric(20,0),
    event numeric(20,0) NOT NULL,
    docvr numeric(20,0) NOT NULL,
    date character varying(10) NOT NULL,
    begtm character varying(20) NOT NULL,
    ecptm character varying(20),
    par numeric(20,0) NOT NULL,
    curr numeric(20,0),
    currrate numeric(16,5),
    "user" numeric(20,0) NOT NULL
);
    DROP TABLE iis.tmp_tic_doc;
       iis         heap    iis    false    8            "           0    0    TABLE tmp_tic_doc    ACL     p   GRANT ALL ON TABLE iis.tmp_tic_doc TO PUBLIC;
GRANT ALL ON TABLE iis.tmp_tic_doc TO postgres WITH GRANT OPTION;
          iis          iis    false    945                       2604    23041    moja_tabela id    DEFAULT     j   ALTER TABLE ONLY iis.moja_tabela ALTER COLUMN id SET DEFAULT nextval('iis.moja_tabela_id_seq'::regclass);
 :   ALTER TABLE iis.moja_tabela ALTER COLUMN id DROP DEFAULT;
       iis          iis    false    831    830                       0    21781    aaa 
   TABLE DATA           3   COPY iis.aaa (id, code, text, coljson) FROM stdin;
    iis          iis    false    700   ��                 0    21790 
   adm_action 
   TABLE DATA           >   COPY iis.adm_action (id, site, code, text, valid) FROM stdin;
    iis          iis    false    702   ��                 0    21795    adm_actionx 
   TABLE DATA           L   COPY iis.adm_actionx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    703   ��                 0    21809    adm_blacklist_token 
   TABLE DATA           A   COPY iis.adm_blacklist_token (id, token, expiration) FROM stdin;
    iis          iis    false    706   ��                  0    21814    adm_dbmserr 
   TABLE DATA           8   COPY iis.adm_dbmserr (id, site, code, text) FROM stdin;
    iis          iis    false    707   ��      !           0    21819    adm_dbparameter 
   TABLE DATA           N   COPY iis.adm_dbparameter (id, site, code, text, comment, version) FROM stdin;
    iis          iis    false    708   �      "           0    21824    adm_message 
   TABLE DATA           8   COPY iis.adm_message (id, site, code, text) FROM stdin;
    iis          iis    false    709   ��      #           0    21829    adm_paruser 
   TABLE DATA           D   COPY iis.adm_paruser (id, site, par, usr, begda, endda) FROM stdin;
    iis          iis    false    710   ��      $           0    21832    adm_roll 
   TABLE DATA           H   COPY iis.adm_roll (id, site, code, text, strukturna, valid) FROM stdin;
    iis          iis    false    711   i�      %           0    21841    adm_rollact 
   TABLE DATA           v   COPY iis.adm_rollact (id, site, roll, action, cre_action, upd_action, del_action, exe_action, all_action) FROM stdin;
    iis          iis    false    712   ��      &           0    21844    adm_rolllink 
   TABLE DATA           A   COPY iis.adm_rolllink (id, site, roll1, roll2, link) FROM stdin;
    iis          iis    false    713   :�      '           0    21847    adm_rollstr 
   TABLE DATA           [   COPY iis.adm_rollstr (id, site, roll, onoff, hijerarhija, objtp, obj, "table") FROM stdin;
    iis          iis    false    714   ��      (           0    21856 	   adm_rollx 
   TABLE DATA           J   COPY iis.adm_rollx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    715   =�      )           0    21866 	   adm_table 
   TABLE DATA           Z   COPY iis.adm_table (id, site, code, text, valid, module, base, url, dropdown) FROM stdin;
    iis          iis    false    717   y�      *           0    21873    adm_user 
   TABLE DATA           �   COPY iis.adm_user (id, site, username, password, firstname, lastname, sapuser, aduser, tip, admin, mail, usergrp, valid, created_at, updated_at) FROM stdin;
    iis          iis    false    718   ��      ,           0    21893    adm_useraddr 
   TABLE DATA           a   COPY iis.adm_useraddr (id, site, usr, "default", adress, city, zip, country, status) FROM stdin;
    iis          postgres    false    721   �      +           0    21882    adm_usergrp 
   TABLE DATA           ?   COPY iis.adm_usergrp (id, site, code, text, valid) FROM stdin;
    iis          iis    false    719   #�      -           0    21906    adm_usergrpx 
   TABLE DATA           M   COPY iis.adm_usergrpx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    723   ��      .           0    21916    adm_userlink 
   TABLE DATA           P   COPY iis.adm_userlink (id, site, user1, user2, begda, endda, "all") FROM stdin;
    iis          iis    false    725   ��      /           0    21919    adm_userlinkpremiss 
   TABLE DATA           K   COPY iis.adm_userlinkpremiss (id, site, userlink, userpermiss) FROM stdin;
    iis          iis    false    726   ��      0           0    21922    adm_userloc 
   TABLE DATA           D   COPY iis.adm_userloc (id, site, usr, loc, begda, endda) FROM stdin;
    iis          iis    false    727   ��      1           0    21925    adm_userpermiss 
   TABLE DATA           ;   COPY iis.adm_userpermiss (id, site, usr, roll) FROM stdin;
    iis          iis    false    728   ��      4           0    21955 	   cmn_ccard 
   TABLE DATA           =   COPY iis.cmn_ccard (id, site, code, text, valid) FROM stdin;
    iis          iis    false    734   h�      5           0    21960 
   cmn_ccardx 
   TABLE DATA           K   COPY iis.cmn_ccardx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    735   ��      6           0    21966    cmn_curr 
   TABLE DATA           P   COPY iis.cmn_curr (id, site, code, text, tp, country, begda, endda) FROM stdin;
    iis          iis    false    736   ��      7           0    21971    cmn_currrate 
   TABLE DATA           W   COPY iis.cmn_currrate (id, site, curr1, curr2, begda, endda, rate, parity) FROM stdin;
    iis          iis    false    737   s�      8           0    21974 	   cmn_currx 
   TABLE DATA           J   COPY iis.cmn_currx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    738   ��      ;           0    22003    cmn_inputtp 
   TABLE DATA           ?   COPY iis.cmn_inputtp (id, site, code, text, valid) FROM stdin;
    iis          iis    false    743   f�      <           0    22008    cmn_inputtpx 
   TABLE DATA           M   COPY iis.cmn_inputtpx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    744   ��      =           0    22018    cmn_link 
   TABLE DATA           L   COPY iis.cmn_link (id, site, code, text, objtp1, objtp2, valid) FROM stdin;
    iis          iis    false    746   ��      >           0    22025 	   cmn_linkx 
   TABLE DATA           J   COPY iis.cmn_linkx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    747   ��      ?           0    22035    cmn_loc 
   TABLE DATA           �   COPY iis.cmn_loc (id, site, code, text, longtext, tp, valid, graftp, latlongs, radius, color, fillcolor, originfillcolor, rownum, seatnum, icon) FROM stdin;
    iis          iis    false    749   ��      @           0    22042 
   cmn_locatt 
   TABLE DATA           >   COPY iis.cmn_locatt (id, site, code, text, valid) FROM stdin;
    iis          iis    false    750   =�      A           0    22049    cmn_locatts 
   TABLE DATA           M   COPY iis.cmn_locatts (id, site, loc, locatt, text, begda, endda) FROM stdin;
    iis          iis    false    751   Z�      B           0    22054    cmn_locattx 
   TABLE DATA           L   COPY iis.cmn_locattx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    752   w�      C           0    22064    cmn_loclink 
   TABLE DATA           �   COPY iis.cmn_loclink (id, site, tp, loctp1, loc1, loctp2, loc2, val, begda, endda, hijerarhija, onoff, color, icon) FROM stdin;
    iis          iis    false    754   ��      D           0    22073    cmn_loclinktp 
   TABLE DATA           A   COPY iis.cmn_loclinktp (id, site, code, text, valid) FROM stdin;
    iis          iis    false    755   ��      E           0    22080    cmn_loclinktpx 
   TABLE DATA           O   COPY iis.cmn_loclinktpx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    756   ��      F           0    22090 
   cmn_locobj 
   TABLE DATA           C   COPY iis.cmn_locobj (id, site, loc, obj, begda, endda) FROM stdin;
    iis          iis    false    758   ��      G           0    22093 	   cmn_loctp 
   TABLE DATA           C   COPY iis.cmn_loctp (id, site, code, text, icon, valid) FROM stdin;
    iis          iis    false    759   �      H           0    22100 
   cmn_loctpx 
   TABLE DATA           K   COPY iis.cmn_loctpx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    760   ?�      I           0    22110    cmn_locx 
   TABLE DATA           I   COPY iis.cmn_locx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    762   ��      J           0    22121    cmn_menu 
   TABLE DATA           k   COPY iis.cmn_menu (id, site, code, text, parentid, link, akction, module, icon, "user", valid) FROM stdin;
    iis          iis    false    764   ��      K           0    22128 	   cmn_menux 
   TABLE DATA           J   COPY iis.cmn_menux (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    765   U�      L           0    22139 
   cmn_module 
   TABLE DATA           F   COPY iis.cmn_module (id, site, code, text, app_id, valid) FROM stdin;
    iis          iis    false    767   r�      M           0    22144    cmn_modulex 
   TABLE DATA           L   COPY iis.cmn_modulex (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    768   ��      2           0    21936    cmn_obj 
   TABLE DATA           L   COPY iis.cmn_obj (id, site, code, text, tp, valid, color, icon) FROM stdin;
    iis          iis    false    731   ��      N           0    22154 
   cmn_objatt 
   TABLE DATA           L   COPY iis.cmn_objatt (id, site, code, text, cmn_objatttp, valid) FROM stdin;
    iis          iis    false    770   ��      O           0    22161    cmn_objatts 
   TABLE DATA           R   COPY iis.cmn_objatts (id, site, obj, cmn_objatt, begda, endda, value) FROM stdin;
    iis          iis    false    771   ��      P           0    22166    cmn_objatttp 
   TABLE DATA           @   COPY iis.cmn_objatttp (id, site, code, text, valid) FROM stdin;
    iis          iis    false    772   �      Q           0    22173    cmn_objatttpx 
   TABLE DATA           N   COPY iis.cmn_objatttpx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    773    �      R           0    22183    cmn_objattx 
   TABLE DATA           L   COPY iis.cmn_objattx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    775   =�      3           0    21943    cmn_objlink 
   TABLE DATA           �   COPY iis.cmn_objlink (id, site, objtp1, obj1, objtp2, obj2, cmn_link, direction, code, text, um, begda, endda, hijerarhija, onoff) FROM stdin;
    iis          iis    false    732   Z�      S           0    22193    cmn_objlink_arr 
   TABLE DATA           g   COPY iis.cmn_objlink_arr (id, site, objtp1, obj1, objtp2, obj2, level, code, begda, endda) FROM stdin;
    iis          iis    false    777   w�      T           0    22196 	   cmn_objtp 
   TABLE DATA           H   COPY iis.cmn_objtp (id, site, code, text, adm_table, valid) FROM stdin;
    iis          iis    false    778   ��      U           0    22203 
   cmn_objtpx 
   TABLE DATA           K   COPY iis.cmn_objtpx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    779   ��      V           0    22213    cmn_objx 
   TABLE DATA           I   COPY iis.cmn_objx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    781   ��      W           0    22223    cmn_par 
   TABLE DATA           �   COPY iis.cmn_par (id, site, code, tp, text, short, address, place, postcode, tel, activity, pib, idnum, pdvnum, begda, endda) FROM stdin;
    iis          iis    false    783   ��      X           0    22228    cmn_paraccount 
   TABLE DATA           j   COPY iis.cmn_paraccount (id, site, cmn_par, bank, account, brojpartije, glavni, begda, endda) FROM stdin;
    iis          iis    false    784   ��      Y           0    22233 
   cmn_paratt 
   TABLE DATA           >   COPY iis.cmn_paratt (id, site, code, text, valid) FROM stdin;
    iis          iis    false    785   �      Z           0    22238    cmn_paratts 
   TABLE DATA           J   COPY iis.cmn_paratts (id, site, par, att, text, begda, endda) FROM stdin;
    iis          iis    false    786   *�      [           0    22243    cmn_parattx 
   TABLE DATA           L   COPY iis.cmn_parattx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    787   G�      \           0    22253    cmn_parcontact 
   TABLE DATA           c   COPY iis.cmn_parcontact (id, site, cmn_par, tp, person, long, tel, mail, other, valid) FROM stdin;
    iis          iis    false    789   d�      ]           0    22260    cmn_parcontacttp 
   TABLE DATA           N   COPY iis.cmn_parcontacttp (id, site, code, text, sys_code, valid) FROM stdin;
    iis          iis    false    790   ��      ^           0    22268    cmn_parcontacttpx 
   TABLE DATA           R   COPY iis.cmn_parcontacttpx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    791   ��      _           0    22278    cmn_parlink 
   TABLE DATA           L   COPY iis.cmn_parlink (id, site, par1, par2, text, begda, endda) FROM stdin;
    iis          iis    false    793   ��      `           0    22283 	   cmn_partp 
   TABLE DATA           =   COPY iis.cmn_partp (id, site, code, text, valid) FROM stdin;
    iis          iis    false    794   ��      a           0    22288 
   cmn_partpx 
   TABLE DATA           K   COPY iis.cmn_partpx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    795   ��      b           0    22298    cmn_parx 
   TABLE DATA           I   COPY iis.cmn_parx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    797   ��      c           0    22309    cmn_paymenttp 
   TABLE DATA           A   COPY iis.cmn_paymenttp (id, site, code, text, valid) FROM stdin;
    iis          iis    false    799   ��      d           0    22314    cmn_paymenttpx 
   TABLE DATA           O   COPY iis.cmn_paymenttpx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    800   *�      e           0    22324    cmn_site 
   TABLE DATA           <   COPY iis.cmn_site (id, site, code, text, valid) FROM stdin;
    iis          iis    false    802   ��      f           0    22331    cmn_tax 
   TABLE DATA           D   COPY iis.cmn_tax (id, site, code, text, country, valid) FROM stdin;
    iis          iis    false    803   ��      g           0    22336    cmn_taxrate 
   TABLE DATA           E   COPY iis.cmn_taxrate (id, site, tax, rate, begda, endda) FROM stdin;
    iis          iis    false    804   s�      h           0    22339    cmn_taxx 
   TABLE DATA           I   COPY iis.cmn_taxx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    805   ��      i           0    22349    cmn_terr 
   TABLE DATA           Q   COPY iis.cmn_terr (id, site, code, text, tp, postcode, begda, endda) FROM stdin;
    iis          iis    false    807   f�      j           0    22352    cmn_terratt 
   TABLE DATA           ?   COPY iis.cmn_terratt (id, site, code, text, valid) FROM stdin;
    iis          iis    false    808   q�      k           0    22359    cmn_terratts 
   TABLE DATA           K   COPY iis.cmn_terratts (id, site, loc, att, text, begda, endda) FROM stdin;
    iis          iis    false    809   ��      l           0    22364    cmn_terrattx 
   TABLE DATA           M   COPY iis.cmn_terrattx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    810   !�      m           0    22374    cmn_terrlink 
   TABLE DATA           O   COPY iis.cmn_terrlink (id, site, terr1, terr2, text, begda, endda) FROM stdin;
    iis          iis    false    812   ��      n           0    22377    cmn_terrlinktp 
   TABLE DATA           B   COPY iis.cmn_terrlinktp (id, site, code, text, valid) FROM stdin;
    iis          iis    false    813   ��      o           0    22382    cmn_terrlinktpx 
   TABLE DATA           P   COPY iis.cmn_terrlinktpx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    814   ��      p           0    22392    cmn_terrloc 
   TABLE DATA           ?   COPY iis.cmn_terrloc (id, terr, loc, begda, endda) FROM stdin;
    iis          iis    false    816   ��      q           0    22395 
   cmn_terrtp 
   TABLE DATA           >   COPY iis.cmn_terrtp (id, site, code, text, valid) FROM stdin;
    iis          iis    false    817   ��      r           0    22400    cmn_terrtpx 
   TABLE DATA           L   COPY iis.cmn_terrtpx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    818   ��      s           0    22410 	   cmn_terrx 
   TABLE DATA           J   COPY iis.cmn_terrx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    820   ��      t           0    22420    cmn_tgp 
   TABLE DATA           D   COPY iis.cmn_tgp (id, site, code, text, country, valid) FROM stdin;
    iis          iis    false    822   ��      u           0    22425 
   cmn_tgptax 
   TABLE DATA           C   COPY iis.cmn_tgptax (id, site, tgp, tax, begda, endda) FROM stdin;
    iis          iis    false    823   #�      v           0    22428    cmn_tgpx 
   TABLE DATA           I   COPY iis.cmn_tgpx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    824   ��      w           0    22438    cmn_um 
   TABLE DATA           :   COPY iis.cmn_um (id, site, code, text, valid) FROM stdin;
    iis          iis    false    826   (�      x           0    22443    cmn_umparity 
   TABLE DATA           P   COPY iis.cmn_umparity (id, site, um1, um2, parity, begda, datumod2) FROM stdin;
    iis          iis    false    827   n�      y           0    22446    cmn_umx 
   TABLE DATA           H   COPY iis.cmn_umx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    828   ��      z           0    22456    moja_tabela 
   TABLE DATA           .   COPY iis.moja_tabela (id, podaci) FROM stdin;
    iis          iis    false    830   ��      |           0    22467 
   tic_agenda 
   TABLE DATA           P   COPY iis.tic_agenda (id, site, code, text, tg, begtm, endtm, valid) FROM stdin;
    iis          iis    false    833   ��      }           0    22474    tic_agendatp 
   TABLE DATA           @   COPY iis.tic_agendatp (id, site, code, text, valid) FROM stdin;
    iis          iis    false    834   �      ~           0    22481    tic_agendatpx 
   TABLE DATA           N   COPY iis.tic_agendatpx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    835   6�                 0    22491    tic_agendax 
   TABLE DATA           L   COPY iis.tic_agendax (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    837   S�      �           0    22501    tic_art 
   TABLE DATA           s   COPY iis.tic_art (id, site, code, text, tp, um, tgp, eancode, qrcode, valid, grp, color, icon, amount) FROM stdin;
    iis          iis    false    839   p�      �           0    22508    tic_artcena 
   TABLE DATA           _   COPY iis.tic_artcena (id, site, event, art, cena, value, terr, begda, endda, curr) FROM stdin;
    iis          iis    false    840   ��      �           0    22511 
   tic_artgrp 
   TABLE DATA           >   COPY iis.tic_artgrp (id, site, code, text, valid) FROM stdin;
    iis          iis    false    841   ��      �           0    22518    tic_artgrpx 
   TABLE DATA           L   COPY iis.tic_artgrpx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    842   ��      �           0    22528    tic_artlink 
   TABLE DATA           <   COPY iis.tic_artlink (id, site, art1, art2, tp) FROM stdin;
    iis          iis    false    844   ��      �           0    22531 
   tic_artloc 
   TABLE DATA           C   COPY iis.tic_artloc (id, site, art, loc, begda, endda) FROM stdin;
    iis          iis    false    845   �      �           0    22534    tic_artprivilege 
   TABLE DATA           V   COPY iis.tic_artprivilege (id, site, art, privilege, begda, endda, value) FROM stdin;
    iis          iis    false    846   �      �           0    22539 
   tic_arttax 
   TABLE DATA           D   COPY iis.tic_arttax (id, art, tax, value, begda, endda) FROM stdin;
    iis          iis    false    847   ;�      �           0    22544 	   tic_arttp 
   TABLE DATA           =   COPY iis.tic_arttp (id, site, code, text, valid) FROM stdin;
    iis          iis    false    848   X�      �           0    22551 
   tic_arttpx 
   TABLE DATA           K   COPY iis.tic_arttpx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    849   u�      �           0    22561    tic_artx 
   TABLE DATA           I   COPY iis.tic_artx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    851   ��      �           0    22572    tic_cena 
   TABLE DATA           M   COPY iis.tic_cena (id, site, code, text, tp, valid, color, icon) FROM stdin;
    iis          iis    false    853   ��      �           0    22579 
   tic_cenatp 
   TABLE DATA           >   COPY iis.tic_cenatp (id, site, code, text, valid) FROM stdin;
    iis          iis    false    854   ��      �           0    22586    tic_cenatpx 
   TABLE DATA           L   COPY iis.tic_cenatpx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    855   ��      �           0    22596 	   tic_cenax 
   TABLE DATA           J   COPY iis.tic_cenax (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    857   �      �           0    22606    tic_chanellseatloc 
   TABLE DATA           ]   COPY iis.tic_chanellseatloc (id, site, chanell, seatloc, count, begda, datumod2) FROM stdin;
    iis          iis    false    859   #�      �           0    22609    tic_channel 
   TABLE DATA           ?   COPY iis.tic_channel (id, site, code, text, valid) FROM stdin;
    iis          iis    false    860   @�      �           0    22616    tic_channeleventpar 
   TABLE DATA           I   COPY iis.tic_channeleventpar (id, site, channel, event, par) FROM stdin;
    iis          iis    false    861   ]�      �           0    22619    tic_channelx 
   TABLE DATA           M   COPY iis.tic_channelx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    862   z�      �           0    22625 
   tic_condtp 
   TABLE DATA           >   COPY iis.tic_condtp (id, site, code, text, valid) FROM stdin;
    iis          iis    false    863   ��      �           0    22632    tic_condtpx 
   TABLE DATA           L   COPY iis.tic_condtpx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    864   n�      �           0    22642    tic_discount 
   TABLE DATA           D   COPY iis.tic_discount (id, site, code, text, tp, valid) FROM stdin;
    iis          iis    false    866   V�      �           0    22649    tic_discounttp 
   TABLE DATA           B   COPY iis.tic_discounttp (id, site, code, text, valid) FROM stdin;
    iis          iis    false    867   s�      �           0    22656    tic_discounttpx 
   TABLE DATA           P   COPY iis.tic_discounttpx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    868   ��      �           0    22666    tic_discountx 
   TABLE DATA           N   COPY iis.tic_discountx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    870   ��      �           0    22676    tic_doc 
   TABLE DATA           �   COPY iis.tic_doc (id, site, docvr, date, tm, curr, currrate, usr, status, docobj, broj, obj2, opis, timecreation, storno, year) FROM stdin;
    iis          iis    false    872   ��      �           0    22682    tic_docb 
   TABLE DATA           <   COPY iis.tic_docb (id, site, doc, tp, bcontent) FROM stdin;
    iis          iis    false    873   ��      �           0    22687    tic_docdelivery 
   TABLE DATA           �   COPY iis.tic_docdelivery (id, site, doc, courier, adress, amount, dat, datdelivery, status, note, parent, country, zip, city) FROM stdin;
    iis          postgres    false    874   �      �           0    22692    tic_docdocslink 
   TABLE DATA           ;   COPY iis.tic_docdocslink (id, site, doc, docs) FROM stdin;
    iis          iis    false    875   !�      �           0    22695    tic_doclink 
   TABLE DATA           @   COPY iis.tic_doclink (id, site, doc1, doc2, "time") FROM stdin;
    iis          iis    false    876   >�      �           0    22698    tic_docpayment 
   TABLE DATA           X   COPY iis.tic_docpayment (id, site, doc, paymenttp, amount, bcontent, ccard) FROM stdin;
    iis          iis    false    877   [�      �           0    22703    tic_docs 
   TABLE DATA           �   COPY iis.tic_docs (id, site, doc, event, loc, art, tgp, taxrate, price, input, output, discount, curr, currrate, duguje, potrazuje, leftcurr, rightcurr, begtm, endtm, status, fee, par, descript, cena, reztm, storno) FROM stdin;
    iis          iis    false    878   x�      �           0    22709    tic_docslink 
   TABLE DATA           C   COPY iis.tic_docslink (id, site, docs1, docs2, "time") FROM stdin;
    iis          iis    false    879   ��      �           0    22712    tic_docsuid 
   TABLE DATA           r   COPY iis.tic_docsuid (id, site, docs, first, last, uid, pib, adress, city, zip, country, phon, email) FROM stdin;
    iis          postgres    false    880   ��      9           0    21984 	   tic_doctp 
   TABLE DATA           K   COPY iis.tic_doctp (id, site, code, text, valid, duguje, znak) FROM stdin;
    iis          iis    false    740   ��      :           0    21993 
   tic_doctpx 
   TABLE DATA           K   COPY iis.tic_doctpx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    741   s�      �           0    22721 	   tic_docvr 
   TABLE DATA           A   COPY iis.tic_docvr (id, site, code, text, tp, valid) FROM stdin;
    iis          iis    false    882   $�      �           0    22728 
   tic_docvrx 
   TABLE DATA           K   COPY iis.tic_docvrx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    883   A�      �           0    22738 	   tic_event 
   TABLE DATA           8  COPY iis.tic_event (id, site, code, text, tp, begda, endda, begtm, endtm, status, descript, note, event, ctg, loc, par, tmp, season, map_extent, map_min_zoom, map_max_zoom, map_max_resolution, tile_extent, tile_size, venue_id, enable_tiles, map_zoom_level, have_background, background_image, loc_id) FROM stdin;
    iis          iis    false    885   ^�      �           0    22744    tic_eventagenda 
   TABLE DATA           E   COPY iis.tic_eventagenda (id, site, event, agenda, date) FROM stdin;
    iis          iis    false    886   {�      �           0    22747    tic_eventart 
   TABLE DATA           n   COPY iis.tic_eventart (id, site, event, art, descript, begda, endda, nart, discount, color, icon) FROM stdin;
    iis          iis    false    887   ��      �           0    22752    tic_eventartcena 
   TABLE DATA           n   COPY iis.tic_eventartcena (id, site, event, art, cena, value, terr, begda, endda, curr, eventart) FROM stdin;
    iis          iis    false    888   ��      �           0    22755    tic_eventartlink 
   TABLE DATA           K   COPY iis.tic_eventartlink (id, site, eventart1, eventart2, tp) FROM stdin;
    iis          iis    false    889   ��      �           0    22758    tic_eventartloc 
   TABLE DATA           T   COPY iis.tic_eventartloc (id, site, eventart, loctp, loc, begda, endda) FROM stdin;
    iis          iis    false    890   ��      �           0    22761    tic_eventatt 
   TABLE DATA           U   COPY iis.tic_eventatt (id, site, code, text, valid, inputtp, ddlist, tp) FROM stdin;
    iis          iis    false    891   �      �           0    22768    tic_eventatts 
   TABLE DATA           f   COPY iis.tic_eventatts (id, site, event, att, value, valid, text, color, icon, condition) FROM stdin;
    iis          iis    false    892   )�      �           0    22774    tic_eventatttp 
   TABLE DATA           B   COPY iis.tic_eventatttp (id, site, code, text, valid) FROM stdin;
    iis          postgres    false    893   F�      �           0    22779    tic_eventatttpx 
   TABLE DATA           P   COPY iis.tic_eventatttpx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          postgres    false    894   c�      �           0    22789    tic_eventattx 
   TABLE DATA           N   COPY iis.tic_eventattx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    896   ��      �           0    22800    tic_eventcenatp 
   TABLE DATA           M   COPY iis.tic_eventcenatp (id, site, event, cenatp, begda, endda) FROM stdin;
    iis          iis    false    898   ��      �           0    22803    tic_eventctg 
   TABLE DATA           @   COPY iis.tic_eventctg (id, site, code, text, valid) FROM stdin;
    iis          iis    false    899   ��      �           0    22810    tic_eventctgx 
   TABLE DATA           N   COPY iis.tic_eventctgx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    900   ��      �           0    22820    tic_eventlink 
   TABLE DATA           D   COPY iis.tic_eventlink (id, site, event1, event2, note) FROM stdin;
    iis          iis    false    902   ��      �           0    22825    tic_eventloc 
   TABLE DATA           T   COPY iis.tic_eventloc (id, site, event, loc, begda, endda, color, icon) FROM stdin;
    iis          iis    false    903   �      �           0    22828    tic_eventobj 
   TABLE DATA           i   COPY iis.tic_eventobj (id, site, event, objtp, obj, begda, endda, begtm, endtm, color, icon) FROM stdin;
    iis          iis    false    904   .�      �           0    22831 
   tic_events 
   TABLE DATA           �   COPY iis.tic_events (id, selection_duration, payment_duration, booking_duration, max_ticket, online_payment, cash_payment, delivery_payment, presale_enabled, presale_until, presale_discount, presale_discount_absolute) FROM stdin;
    iis          iis    false    905   K�      �           0    22834    tic_eventst 
   TABLE DATA           �   COPY iis.tic_eventst (id, site, loc1, code1, text1, ntp1, loc2, code2, text2, ntp2, event, graftp, latlongs, radius, color, fillcolor, originfillcolor, rownum, art, cart, nart, longtext, tp1, tp2, kol, status) FROM stdin;
    iis          iis    false    906   h�      �           0    22839    tic_eventtp 
   TABLE DATA           ?   COPY iis.tic_eventtp (id, site, code, text, valid) FROM stdin;
    iis          iis    false    907   ��      �           0    22846    tic_eventtps 
   TABLE DATA           P   COPY iis.tic_eventtps (id, site, eventtp, att, value, begda, endda) FROM stdin;
    iis          iis    false    908   ��      �           0    22851    tic_eventtpx 
   TABLE DATA           M   COPY iis.tic_eventtpx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    909   ��      �           0    22861 
   tic_eventx 
   TABLE DATA           K   COPY iis.tic_eventx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    911   ��      �           0    22872    tic_parprivilege 
   TABLE DATA           _   COPY iis.tic_parprivilege (id, site, par, privilege, begda, endda, maxprc, maxval) FROM stdin;
    iis          iis    false    913   ��      �           0    22875    tic_paycard 
   TABLE DATA           j   COPY iis.tic_paycard (id, site, docpayment, ccard, owner, cardnum, code, dat, amount, status) FROM stdin;
    iis          iis    false    914   �      �           0    22878    tic_privilege 
   TABLE DATA           Q   COPY iis.tic_privilege (id, site, code, text, tp, limitirano, valid) FROM stdin;
    iis          iis    false    915   3�      �           0    22886    tic_privilegecond 
   TABLE DATA           �   COPY iis.tic_privilegecond (id, site, privilege, begcondtp, begcondition, begvalue, endcondtp, endcondition, endvalue, begda, endda) FROM stdin;
    iis          iis    false    916   P�      �           0    22889    tic_privilegediscount 
   TABLE DATA           `   COPY iis.tic_privilegediscount (id, site, privilege, discount, value, begda, endda) FROM stdin;
    iis          iis    false    917   m�      �           0    22892    tic_privilegelink 
   TABLE DATA           X   COPY iis.tic_privilegelink (id, site, privilege1, privilege2, begda, endda) FROM stdin;
    iis          iis    false    918   ��      �           0    22895    tic_privilegetp 
   TABLE DATA           C   COPY iis.tic_privilegetp (id, site, code, text, valid) FROM stdin;
    iis          iis    false    919   ��      �           0    22902    tic_privilegetpx 
   TABLE DATA           Q   COPY iis.tic_privilegetpx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    920   ��      �           0    22912    tic_privilegex 
   TABLE DATA           O   COPY iis.tic_privilegex (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    922   ��      �           0    22922 
   tic_season 
   TABLE DATA           >   COPY iis.tic_season (id, site, code, text, valid) FROM stdin;
    iis          iis    false    924   ��      �           0    22929    tic_seasonx 
   TABLE DATA           L   COPY iis.tic_seasonx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    925   �      �           0    22939    tic_seat 
   TABLE DATA           @   COPY iis.tic_seat (id, site, code, text, tp, valid) FROM stdin;
    iis          iis    false    927   8�      �           0    22946    tic_seatloc 
   TABLE DATA           L   COPY iis.tic_seatloc (id, site, loc, seat, count, begda, endda) FROM stdin;
    iis          iis    false    928   U�      �           0    22951 
   tic_seattp 
   TABLE DATA           >   COPY iis.tic_seattp (id, site, code, text, valid) FROM stdin;
    iis          iis    false    929   r�      �           0    22958    tic_seattpatt 
   TABLE DATA           A   COPY iis.tic_seattpatt (id, site, code, text, valid) FROM stdin;
    iis          iis    false    930   ��      �           0    22965    tic_seattpatts 
   TABLE DATA           Q   COPY iis.tic_seattpatts (id, site, seattp, att, value, begda, endda) FROM stdin;
    iis          iis    false    931   ��      �           0    22970    tic_seattpattx 
   TABLE DATA           O   COPY iis.tic_seattpattx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    932   ��      �           0    22976    tic_seattpx 
   TABLE DATA           L   COPY iis.tic_seattpx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    933   ��      �           0    22982 	   tic_seatx 
   TABLE DATA           J   COPY iis.tic_seatx (id, site, tableid, lang, grammcase, text) FROM stdin;
    iis          iis    false    934   �      �           0    22988    tic_speccheck 
   TABLE DATA           ]   COPY iis.tic_speccheck (id, site, docpayment, bank, code1, code2, code3, amount) FROM stdin;
    iis          iis    false    935    �      �           0    22993 
   tic_stampa 
   TABLE DATA           O   COPY iis.tic_stampa (id, site, docs, "time", bcontent, status, tp) FROM stdin;
    iis          iis    false    936   =�      �           0    22999    tic_ticketst 
   TABLE DATA           \   COPY iis.tic_ticketst (id, data, eventid, articleid, tickettype, width, height) FROM stdin;
    iis          postgres    false    938   Z�      �           0    23004    tic_user_messages 
   TABLE DATA           P   COPY iis.tic_user_messages (id, userid, message_text, message_read) FROM stdin;
    iis          postgres    false    939   w�      �           0    23009    tic_user_ticket 
   TABLE DATA           o   COPY iis.tic_user_ticket (id, data, eventid, articleid, tickettype, userid, seatid, width, height) FROM stdin;
    iis          postgres    false    940   ��      �           0    23014 	   tic_venue 
   TABLE DATA           �   COPY iis.tic_venue (venue_id, venue_name, venue_type, map_extent, map_min_zoom, map_max_zoom, map_max_resolution, tile_extent, tile_size, loc_id, enable_tiles, map_zoom_level, have_background, background_image, site, code) FROM stdin;
    iis          iis    false    941   ��      �           0    23019    tic_venue_item 
   TABLE DATA           m   COPY iis.tic_venue_item (id, type, location, radius, venue, venue_id, sector, row_num, seat_num) FROM stdin;
    iis          iis    false    942   ��      �           0    23024    tmp_cmn_loc 
   TABLE DATA           I   COPY iis.tmp_cmn_loc (id, site, code, text, long, tp, valid) FROM stdin;
    iis          iis    false    943   ��      �           0    23031    tmp_cmn_loctp 
   TABLE DATA           A   COPY iis.tmp_cmn_loctp (id, site, code, text, valid) FROM stdin;
    iis          iis    false    944   �      �           0    23038    tmp_tic_doc 
   TABLE DATA           k   COPY iis.tmp_tic_doc (id, site, event, docvr, date, begtm, ecptm, par, curr, currrate, "user") FROM stdin;
    iis          iis    false    945   %�      "           0    0    moja_tabela_id_seq    SEQUENCE SET     =   SELECT pg_catalog.setval('iis.moja_tabela_id_seq', 1, true);
          iis          iis    false    831            "           0    0    tic_table_id_seq    SEQUENCE SET     M   SELECT pg_catalog.setval('iis.tic_table_id_seq', 5000000000000019374, true);
          iis          iis    false    937            �           2606    23047    adm_user ak_adm_korisnik 
   CONSTRAINT     T   ALTER TABLE ONLY iis.adm_user
    ADD CONSTRAINT ak_adm_korisnik UNIQUE (username);
 ?   ALTER TABLE ONLY iis.adm_user DROP CONSTRAINT ak_adm_korisnik;
       iis            iis    false    718            �           2606    23049 #   adm_userpermiss ak_adm_korisnikrola 
   CONSTRAINT     `   ALTER TABLE ONLY iis.adm_userpermiss
    ADD CONSTRAINT ak_adm_korisnikrola UNIQUE (usr, roll);
 J   ALTER TABLE ONLY iis.adm_userpermiss DROP CONSTRAINT ak_adm_korisnikrola;
       iis            iis    false    728    728            s           2606    23051    moja_tabela moja_tabela_pkey 
   CONSTRAINT     W   ALTER TABLE ONLY iis.moja_tabela
    ADD CONSTRAINT moja_tabela_pkey PRIMARY KEY (id);
 C   ALTER TABLE ONLY iis.moja_tabela DROP CONSTRAINT moja_tabela_pkey;
       iis            iis    false    830            �           2606    23053    adm_actionx pk_adm_actionx 
   CONSTRAINT     U   ALTER TABLE ONLY iis.adm_actionx
    ADD CONSTRAINT pk_adm_actionx PRIMARY KEY (id);
 A   ALTER TABLE ONLY iis.adm_actionx DROP CONSTRAINT pk_adm_actionx;
       iis            iis    false    703            �           2606    23055 *   adm_blacklist_token pk_adm_blacklist_token 
   CONSTRAINT     e   ALTER TABLE ONLY iis.adm_blacklist_token
    ADD CONSTRAINT pk_adm_blacklist_token PRIMARY KEY (id);
 Q   ALTER TABLE ONLY iis.adm_blacklist_token DROP CONSTRAINT pk_adm_blacklist_token;
       iis            iis    false    706            �           2606    23057    adm_dbmserr pk_adm_dbmsgreska 
   CONSTRAINT     X   ALTER TABLE ONLY iis.adm_dbmserr
    ADD CONSTRAINT pk_adm_dbmsgreska PRIMARY KEY (id);
 D   ALTER TABLE ONLY iis.adm_dbmserr DROP CONSTRAINT pk_adm_dbmsgreska;
       iis            iis    false    707            �           2606    23059 "   adm_dbparameter pk_adm_dbparametar 
   CONSTRAINT     ]   ALTER TABLE ONLY iis.adm_dbparameter
    ADD CONSTRAINT pk_adm_dbparametar PRIMARY KEY (id);
 I   ALTER TABLE ONLY iis.adm_dbparameter DROP CONSTRAINT pk_adm_dbparametar;
       iis            iis    false    708            �           2606    23061    adm_user pk_adm_korisnik 
   CONSTRAINT     S   ALTER TABLE ONLY iis.adm_user
    ADD CONSTRAINT pk_adm_korisnik PRIMARY KEY (id);
 ?   ALTER TABLE ONLY iis.adm_user DROP CONSTRAINT pk_adm_korisnik;
       iis            iis    false    718            �           2606    23063 #   adm_userpermiss pk_adm_korisnikrola 
   CONSTRAINT     ^   ALTER TABLE ONLY iis.adm_userpermiss
    ADD CONSTRAINT pk_adm_korisnikrola PRIMARY KEY (id);
 J   ALTER TABLE ONLY iis.adm_userpermiss DROP CONSTRAINT pk_adm_korisnikrola;
       iis            iis    false    728                       2606    23065    cmn_menu pk_adm_menu 
   CONSTRAINT     O   ALTER TABLE ONLY iis.cmn_menu
    ADD CONSTRAINT pk_adm_menu PRIMARY KEY (id);
 ;   ALTER TABLE ONLY iis.cmn_menu DROP CONSTRAINT pk_adm_menu;
       iis            iis    false    764                       2606    23067    cmn_module pk_adm_modul 
   CONSTRAINT     R   ALTER TABLE ONLY iis.cmn_module
    ADD CONSTRAINT pk_adm_modul PRIMARY KEY (id);
 >   ALTER TABLE ONLY iis.cmn_module DROP CONSTRAINT pk_adm_modul;
       iis            iis    false    767            �           2606    23069    adm_paruser pk_adm_paruser 
   CONSTRAINT     U   ALTER TABLE ONLY iis.adm_paruser
    ADD CONSTRAINT pk_adm_paruser PRIMARY KEY (id);
 A   ALTER TABLE ONLY iis.adm_paruser DROP CONSTRAINT pk_adm_paruser;
       iis            iis    false    710            �           2606    23071    adm_message pk_adm_poruka 
   CONSTRAINT     T   ALTER TABLE ONLY iis.adm_message
    ADD CONSTRAINT pk_adm_poruka PRIMARY KEY (id);
 @   ALTER TABLE ONLY iis.adm_message DROP CONSTRAINT pk_adm_poruka;
       iis            iis    false    709            �           2606    23073    adm_roll pk_adm_rola 
   CONSTRAINT     O   ALTER TABLE ONLY iis.adm_roll
    ADD CONSTRAINT pk_adm_rola PRIMARY KEY (id);
 ;   ALTER TABLE ONLY iis.adm_roll DROP CONSTRAINT pk_adm_rola;
       iis            iis    false    711            �           2606    23075    adm_action pk_adm_rolaakcija 
   CONSTRAINT     W   ALTER TABLE ONLY iis.adm_action
    ADD CONSTRAINT pk_adm_rolaakcija PRIMARY KEY (id);
 C   ALTER TABLE ONLY iis.adm_action DROP CONSTRAINT pk_adm_rolaakcija;
       iis            iis    false    702            �           2606    23077    adm_rollact pk_adm_rollact 
   CONSTRAINT     U   ALTER TABLE ONLY iis.adm_rollact
    ADD CONSTRAINT pk_adm_rollact PRIMARY KEY (id);
 A   ALTER TABLE ONLY iis.adm_rollact DROP CONSTRAINT pk_adm_rollact;
       iis            iis    false    712            �           2606    23079    adm_rolllink pk_adm_rolllink 
   CONSTRAINT     W   ALTER TABLE ONLY iis.adm_rolllink
    ADD CONSTRAINT pk_adm_rolllink PRIMARY KEY (id);
 C   ALTER TABLE ONLY iis.adm_rolllink DROP CONSTRAINT pk_adm_rolllink;
       iis            iis    false    713            �           2606    23081    adm_rollx pk_adm_rollx 
   CONSTRAINT     Q   ALTER TABLE ONLY iis.adm_rollx
    ADD CONSTRAINT pk_adm_rollx PRIMARY KEY (id);
 =   ALTER TABLE ONLY iis.adm_rollx DROP CONSTRAINT pk_adm_rollx;
       iis            iis    false    715            �           2606    23083    adm_rollstr pk_adm_strrole 
   CONSTRAINT     U   ALTER TABLE ONLY iis.adm_rollstr
    ADD CONSTRAINT pk_adm_strrole PRIMARY KEY (id);
 A   ALTER TABLE ONLY iis.adm_rollstr DROP CONSTRAINT pk_adm_strrole;
       iis            iis    false    714            �           2606    23085    adm_table pk_adm_table 
   CONSTRAINT     Q   ALTER TABLE ONLY iis.adm_table
    ADD CONSTRAINT pk_adm_table PRIMARY KEY (id);
 =   ALTER TABLE ONLY iis.adm_table DROP CONSTRAINT pk_adm_table;
       iis            iis    false    717            �           2606    23087    adm_useraddr pk_adm_useraddr 
   CONSTRAINT     W   ALTER TABLE ONLY iis.adm_useraddr
    ADD CONSTRAINT pk_adm_useraddr PRIMARY KEY (id);
 C   ALTER TABLE ONLY iis.adm_useraddr DROP CONSTRAINT pk_adm_useraddr;
       iis            postgres    false    721            �           2606    23089    adm_usergrp pk_adm_usergrp 
   CONSTRAINT     U   ALTER TABLE ONLY iis.adm_usergrp
    ADD CONSTRAINT pk_adm_usergrp PRIMARY KEY (id);
 A   ALTER TABLE ONLY iis.adm_usergrp DROP CONSTRAINT pk_adm_usergrp;
       iis            iis    false    719            �           2606    23091    adm_usergrpx pk_adm_usergrpx 
   CONSTRAINT     W   ALTER TABLE ONLY iis.adm_usergrpx
    ADD CONSTRAINT pk_adm_usergrpx PRIMARY KEY (id);
 C   ALTER TABLE ONLY iis.adm_usergrpx DROP CONSTRAINT pk_adm_usergrpx;
       iis            iis    false    723            �           2606    23093    adm_userlink pk_adm_userlink 
   CONSTRAINT     W   ALTER TABLE ONLY iis.adm_userlink
    ADD CONSTRAINT pk_adm_userlink PRIMARY KEY (id);
 C   ALTER TABLE ONLY iis.adm_userlink DROP CONSTRAINT pk_adm_userlink;
       iis            iis    false    725            �           2606    23095 *   adm_userlinkpremiss pk_adm_userlinkpremiss 
   CONSTRAINT     e   ALTER TABLE ONLY iis.adm_userlinkpremiss
    ADD CONSTRAINT pk_adm_userlinkpremiss PRIMARY KEY (id);
 Q   ALTER TABLE ONLY iis.adm_userlinkpremiss DROP CONSTRAINT pk_adm_userlinkpremiss;
       iis            iis    false    726            �           2606    23097    adm_userloc pk_adm_userloc 
   CONSTRAINT     U   ALTER TABLE ONLY iis.adm_userloc
    ADD CONSTRAINT pk_adm_userloc PRIMARY KEY (id);
 A   ALTER TABLE ONLY iis.adm_userloc DROP CONSTRAINT pk_adm_userloc;
       iis            iis    false    727            �           2606    23099    cmn_ccard pk_cmn_ccard 
   CONSTRAINT     Q   ALTER TABLE ONLY iis.cmn_ccard
    ADD CONSTRAINT pk_cmn_ccard PRIMARY KEY (id);
 =   ALTER TABLE ONLY iis.cmn_ccard DROP CONSTRAINT pk_cmn_ccard;
       iis            iis    false    734            �           2606    23101    cmn_ccardx pk_cmn_ccardx 
   CONSTRAINT     S   ALTER TABLE ONLY iis.cmn_ccardx
    ADD CONSTRAINT pk_cmn_ccardx PRIMARY KEY (id);
 ?   ALTER TABLE ONLY iis.cmn_ccardx DROP CONSTRAINT pk_cmn_ccardx;
       iis            iis    false    735            �           2606    23103    cmn_curr pk_cmn_curr 
   CONSTRAINT     O   ALTER TABLE ONLY iis.cmn_curr
    ADD CONSTRAINT pk_cmn_curr PRIMARY KEY (id);
 ;   ALTER TABLE ONLY iis.cmn_curr DROP CONSTRAINT pk_cmn_curr;
       iis            iis    false    736            �           2606    23105    cmn_currrate pk_cmn_currrate 
   CONSTRAINT     W   ALTER TABLE ONLY iis.cmn_currrate
    ADD CONSTRAINT pk_cmn_currrate PRIMARY KEY (id);
 C   ALTER TABLE ONLY iis.cmn_currrate DROP CONSTRAINT pk_cmn_currrate;
       iis            iis    false    737            �           2606    23107    cmn_currx pk_cmn_currx 
   CONSTRAINT     Q   ALTER TABLE ONLY iis.cmn_currx
    ADD CONSTRAINT pk_cmn_currx PRIMARY KEY (id);
 =   ALTER TABLE ONLY iis.cmn_currx DROP CONSTRAINT pk_cmn_currx;
       iis            iis    false    738            �           2606    23109    cmn_inputtp pk_cmn_inputtp 
   CONSTRAINT     U   ALTER TABLE ONLY iis.cmn_inputtp
    ADD CONSTRAINT pk_cmn_inputtp PRIMARY KEY (id);
 A   ALTER TABLE ONLY iis.cmn_inputtp DROP CONSTRAINT pk_cmn_inputtp;
       iis            iis    false    743            �           2606    23111    cmn_inputtpx pk_cmn_inputtpx 
   CONSTRAINT     W   ALTER TABLE ONLY iis.cmn_inputtpx
    ADD CONSTRAINT pk_cmn_inputtpx PRIMARY KEY (id);
 C   ALTER TABLE ONLY iis.cmn_inputtpx DROP CONSTRAINT pk_cmn_inputtpx;
       iis            iis    false    744            �           2606    23113    cmn_link pk_cmn_link 
   CONSTRAINT     O   ALTER TABLE ONLY iis.cmn_link
    ADD CONSTRAINT pk_cmn_link PRIMARY KEY (id);
 ;   ALTER TABLE ONLY iis.cmn_link DROP CONSTRAINT pk_cmn_link;
       iis            iis    false    746            �           2606    23115    cmn_linkx pk_cmn_linkx 
   CONSTRAINT     Q   ALTER TABLE ONLY iis.cmn_linkx
    ADD CONSTRAINT pk_cmn_linkx PRIMARY KEY (id);
 =   ALTER TABLE ONLY iis.cmn_linkx DROP CONSTRAINT pk_cmn_linkx;
       iis            iis    false    747            �           2606    23117    cmn_loc pk_cmn_loc 
   CONSTRAINT     M   ALTER TABLE ONLY iis.cmn_loc
    ADD CONSTRAINT pk_cmn_loc PRIMARY KEY (id);
 9   ALTER TABLE ONLY iis.cmn_loc DROP CONSTRAINT pk_cmn_loc;
       iis            iis    false    749            �           2606    23119    cmn_locattx pk_cmn_locattx 
   CONSTRAINT     U   ALTER TABLE ONLY iis.cmn_locattx
    ADD CONSTRAINT pk_cmn_locattx PRIMARY KEY (id);
 A   ALTER TABLE ONLY iis.cmn_locattx DROP CONSTRAINT pk_cmn_locattx;
       iis            iis    false    752            �           2606    23121     cmn_loclinktpx pk_cmn_loclinktpx 
   CONSTRAINT     [   ALTER TABLE ONLY iis.cmn_loclinktpx
    ADD CONSTRAINT pk_cmn_loclinktpx PRIMARY KEY (id);
 G   ALTER TABLE ONLY iis.cmn_loclinktpx DROP CONSTRAINT pk_cmn_loclinktpx;
       iis            iis    false    756            �           2606    23123    cmn_locobj pk_cmn_locobj 
   CONSTRAINT     S   ALTER TABLE ONLY iis.cmn_locobj
    ADD CONSTRAINT pk_cmn_locobj PRIMARY KEY (id);
 ?   ALTER TABLE ONLY iis.cmn_locobj DROP CONSTRAINT pk_cmn_locobj;
       iis            iis    false    758            �           2606    23125    cmn_loctp pk_cmn_loctp 
   CONSTRAINT     Q   ALTER TABLE ONLY iis.cmn_loctp
    ADD CONSTRAINT pk_cmn_loctp PRIMARY KEY (id);
 =   ALTER TABLE ONLY iis.cmn_loctp DROP CONSTRAINT pk_cmn_loctp;
       iis            iis    false    759            �           2606    23127    cmn_loctpx pk_cmn_loctpx 
   CONSTRAINT     S   ALTER TABLE ONLY iis.cmn_loctpx
    ADD CONSTRAINT pk_cmn_loctpx PRIMARY KEY (id);
 ?   ALTER TABLE ONLY iis.cmn_loctpx DROP CONSTRAINT pk_cmn_loctpx;
       iis            iis    false    760                        2606    23129    cmn_locx pk_cmn_locx 
   CONSTRAINT     O   ALTER TABLE ONLY iis.cmn_locx
    ADD CONSTRAINT pk_cmn_locx PRIMARY KEY (id);
 ;   ALTER TABLE ONLY iis.cmn_locx DROP CONSTRAINT pk_cmn_locx;
       iis            iis    false    762                       2606    23131    tmp_cmn_loc pk_cmn_lokacija 
   CONSTRAINT     V   ALTER TABLE ONLY iis.tmp_cmn_loc
    ADD CONSTRAINT pk_cmn_lokacija PRIMARY KEY (id);
 B   ALTER TABLE ONLY iis.tmp_cmn_loc DROP CONSTRAINT pk_cmn_lokacija;
       iis            iis    false    943            �           2606    23133     cmn_loclink pk_cmn_lokacijaodnos 
   CONSTRAINT     [   ALTER TABLE ONLY iis.cmn_loclink
    ADD CONSTRAINT pk_cmn_lokacijaodnos PRIMARY KEY (id);
 G   ALTER TABLE ONLY iis.cmn_loclink DROP CONSTRAINT pk_cmn_lokacijaodnos;
       iis            iis    false    754            �           2606    23135 "   cmn_locatts pk_cmn_lokacijaosobine 
   CONSTRAINT     ]   ALTER TABLE ONLY iis.cmn_locatts
    ADD CONSTRAINT pk_cmn_lokacijaosobine PRIMARY KEY (id);
 I   ALTER TABLE ONLY iis.cmn_locatts DROP CONSTRAINT pk_cmn_lokacijaosobine;
       iis            iis    false    751            !           2606    23137     tmp_cmn_loctp pk_cmn_lokacijatip 
   CONSTRAINT     [   ALTER TABLE ONLY iis.tmp_cmn_loctp
    ADD CONSTRAINT pk_cmn_lokacijatip PRIMARY KEY (id);
 G   ALTER TABLE ONLY iis.tmp_cmn_loctp DROP CONSTRAINT pk_cmn_lokacijatip;
       iis            iis    false    944            �           2606    23139 $   cmn_locatt pk_cmn_lokacijatiposobina 
   CONSTRAINT     _   ALTER TABLE ONLY iis.cmn_locatt
    ADD CONSTRAINT pk_cmn_lokacijatiposobina PRIMARY KEY (id);
 K   ALTER TABLE ONLY iis.cmn_locatt DROP CONSTRAINT pk_cmn_lokacijatiposobina;
       iis            iis    false    750            �           2606    23141 $   cmn_loclinktp pk_cmn_lokacijavezatip 
   CONSTRAINT     _   ALTER TABLE ONLY iis.cmn_loclinktp
    ADD CONSTRAINT pk_cmn_lokacijavezatip PRIMARY KEY (id);
 K   ALTER TABLE ONLY iis.cmn_loclinktp DROP CONSTRAINT pk_cmn_lokacijavezatip;
       iis            iis    false    755                       2606    23143    cmn_menux pk_cmn_menux 
   CONSTRAINT     Q   ALTER TABLE ONLY iis.cmn_menux
    ADD CONSTRAINT pk_cmn_menux PRIMARY KEY (id);
 =   ALTER TABLE ONLY iis.cmn_menux DROP CONSTRAINT pk_cmn_menux;
       iis            iis    false    765            
           2606    23145    cmn_modulex pk_cmn_modulex 
   CONSTRAINT     U   ALTER TABLE ONLY iis.cmn_modulex
    ADD CONSTRAINT pk_cmn_modulex PRIMARY KEY (id);
 A   ALTER TABLE ONLY iis.cmn_modulex DROP CONSTRAINT pk_cmn_modulex;
       iis            iis    false    768            �           2606    23147    cmn_obj pk_cmn_obj 
   CONSTRAINT     M   ALTER TABLE ONLY iis.cmn_obj
    ADD CONSTRAINT pk_cmn_obj PRIMARY KEY (id);
 9   ALTER TABLE ONLY iis.cmn_obj DROP CONSTRAINT pk_cmn_obj;
       iis            iis    false    731                       2606    23149    cmn_objatt pk_cmn_objatt 
   CONSTRAINT     S   ALTER TABLE ONLY iis.cmn_objatt
    ADD CONSTRAINT pk_cmn_objatt PRIMARY KEY (id);
 ?   ALTER TABLE ONLY iis.cmn_objatt DROP CONSTRAINT pk_cmn_objatt;
       iis            iis    false    770                       2606    23151    cmn_objatts pk_cmn_objatts 
   CONSTRAINT     U   ALTER TABLE ONLY iis.cmn_objatts
    ADD CONSTRAINT pk_cmn_objatts PRIMARY KEY (id);
 A   ALTER TABLE ONLY iis.cmn_objatts DROP CONSTRAINT pk_cmn_objatts;
       iis            iis    false    771                       2606    23153    cmn_objatttp pk_cmn_objatttp 
   CONSTRAINT     W   ALTER TABLE ONLY iis.cmn_objatttp
    ADD CONSTRAINT pk_cmn_objatttp PRIMARY KEY (id);
 C   ALTER TABLE ONLY iis.cmn_objatttp DROP CONSTRAINT pk_cmn_objatttp;
       iis            iis    false    772                       2606    23155    cmn_objatttpx pk_cmn_objatttpx 
   CONSTRAINT     Y   ALTER TABLE ONLY iis.cmn_objatttpx
    ADD CONSTRAINT pk_cmn_objatttpx PRIMARY KEY (id);
 E   ALTER TABLE ONLY iis.cmn_objatttpx DROP CONSTRAINT pk_cmn_objatttpx;
       iis            iis    false    773                       2606    23157    cmn_objattx pk_cmn_objattx 
   CONSTRAINT     U   ALTER TABLE ONLY iis.cmn_objattx
    ADD CONSTRAINT pk_cmn_objattx PRIMARY KEY (id);
 A   ALTER TABLE ONLY iis.cmn_objattx DROP CONSTRAINT pk_cmn_objattx;
       iis            iis    false    775            �           2606    23159    cmn_objlink pk_cmn_objlink 
   CONSTRAINT     U   ALTER TABLE ONLY iis.cmn_objlink
    ADD CONSTRAINT pk_cmn_objlink PRIMARY KEY (id);
 A   ALTER TABLE ONLY iis.cmn_objlink DROP CONSTRAINT pk_cmn_objlink;
       iis            iis    false    732                       2606    23161 "   cmn_objlink_arr pk_cmn_objlink_arr 
   CONSTRAINT     ]   ALTER TABLE ONLY iis.cmn_objlink_arr
    ADD CONSTRAINT pk_cmn_objlink_arr PRIMARY KEY (id);
 I   ALTER TABLE ONLY iis.cmn_objlink_arr DROP CONSTRAINT pk_cmn_objlink_arr;
       iis            iis    false    777                       2606    23163    cmn_objtp pk_cmn_objtp 
   CONSTRAINT     Q   ALTER TABLE ONLY iis.cmn_objtp
    ADD CONSTRAINT pk_cmn_objtp PRIMARY KEY (id);
 =   ALTER TABLE ONLY iis.cmn_objtp DROP CONSTRAINT pk_cmn_objtp;
       iis            iis    false    778                       2606    23165    cmn_objtpx pk_cmn_objtpx 
   CONSTRAINT     S   ALTER TABLE ONLY iis.cmn_objtpx
    ADD CONSTRAINT pk_cmn_objtpx PRIMARY KEY (id);
 ?   ALTER TABLE ONLY iis.cmn_objtpx DROP CONSTRAINT pk_cmn_objtpx;
       iis            iis    false    779                       2606    23167    cmn_objx pk_cmn_objx 
   CONSTRAINT     O   ALTER TABLE ONLY iis.cmn_objx
    ADD CONSTRAINT pk_cmn_objx PRIMARY KEY (id);
 ;   ALTER TABLE ONLY iis.cmn_objx DROP CONSTRAINT pk_cmn_objx;
       iis            iis    false    781            "           2606    23169    cmn_par pk_cmn_par 
   CONSTRAINT     M   ALTER TABLE ONLY iis.cmn_par
    ADD CONSTRAINT pk_cmn_par PRIMARY KEY (id);
 9   ALTER TABLE ONLY iis.cmn_par DROP CONSTRAINT pk_cmn_par;
       iis            iis    false    783            $           2606    23171     cmn_paraccount pk_cmn_paraccount 
   CONSTRAINT     [   ALTER TABLE ONLY iis.cmn_paraccount
    ADD CONSTRAINT pk_cmn_paraccount PRIMARY KEY (id);
 G   ALTER TABLE ONLY iis.cmn_paraccount DROP CONSTRAINT pk_cmn_paraccount;
       iis            iis    false    784            '           2606    23173    cmn_paratt pk_cmn_paratt 
   CONSTRAINT     S   ALTER TABLE ONLY iis.cmn_paratt
    ADD CONSTRAINT pk_cmn_paratt PRIMARY KEY (id);
 ?   ALTER TABLE ONLY iis.cmn_paratt DROP CONSTRAINT pk_cmn_paratt;
       iis            iis    false    785            )           2606    23175    cmn_paratts pk_cmn_paratts 
   CONSTRAINT     U   ALTER TABLE ONLY iis.cmn_paratts
    ADD CONSTRAINT pk_cmn_paratts PRIMARY KEY (id);
 A   ALTER TABLE ONLY iis.cmn_paratts DROP CONSTRAINT pk_cmn_paratts;
       iis            iis    false    786            +           2606    23177    cmn_parattx pk_cmn_parattx 
   CONSTRAINT     U   ALTER TABLE ONLY iis.cmn_parattx
    ADD CONSTRAINT pk_cmn_parattx PRIMARY KEY (id);
 A   ALTER TABLE ONLY iis.cmn_parattx DROP CONSTRAINT pk_cmn_parattx;
       iis            iis    false    787            -           2606    23179     cmn_parcontact pk_cmn_parcontact 
   CONSTRAINT     [   ALTER TABLE ONLY iis.cmn_parcontact
    ADD CONSTRAINT pk_cmn_parcontact PRIMARY KEY (id);
 G   ALTER TABLE ONLY iis.cmn_parcontact DROP CONSTRAINT pk_cmn_parcontact;
       iis            iis    false    789            0           2606    23181 $   cmn_parcontacttp pk_cmn_parcontacttp 
   CONSTRAINT     _   ALTER TABLE ONLY iis.cmn_parcontacttp
    ADD CONSTRAINT pk_cmn_parcontacttp PRIMARY KEY (id);
 K   ALTER TABLE ONLY iis.cmn_parcontacttp DROP CONSTRAINT pk_cmn_parcontacttp;
       iis            iis    false    790            2           2606    23183 &   cmn_parcontacttpx pk_cmn_parcontacttpx 
   CONSTRAINT     a   ALTER TABLE ONLY iis.cmn_parcontacttpx
    ADD CONSTRAINT pk_cmn_parcontacttpx PRIMARY KEY (id);
 M   ALTER TABLE ONLY iis.cmn_parcontacttpx DROP CONSTRAINT pk_cmn_parcontacttpx;
       iis            iis    false    791            4           2606    23185    cmn_parlink pk_cmn_parlink 
   CONSTRAINT     U   ALTER TABLE ONLY iis.cmn_parlink
    ADD CONSTRAINT pk_cmn_parlink PRIMARY KEY (id);
 A   ALTER TABLE ONLY iis.cmn_parlink DROP CONSTRAINT pk_cmn_parlink;
       iis            iis    false    793            7           2606    23187    cmn_partp pk_cmn_partp 
   CONSTRAINT     Q   ALTER TABLE ONLY iis.cmn_partp
    ADD CONSTRAINT pk_cmn_partp PRIMARY KEY (id);
 =   ALTER TABLE ONLY iis.cmn_partp DROP CONSTRAINT pk_cmn_partp;
       iis            iis    false    794            9           2606    23189    cmn_partpx pk_cmn_partpx 
   CONSTRAINT     S   ALTER TABLE ONLY iis.cmn_partpx
    ADD CONSTRAINT pk_cmn_partpx PRIMARY KEY (id);
 ?   ALTER TABLE ONLY iis.cmn_partpx DROP CONSTRAINT pk_cmn_partpx;
       iis            iis    false    795            ;           2606    23191    cmn_parx pk_cmn_parx 
   CONSTRAINT     O   ALTER TABLE ONLY iis.cmn_parx
    ADD CONSTRAINT pk_cmn_parx PRIMARY KEY (id);
 ;   ALTER TABLE ONLY iis.cmn_parx DROP CONSTRAINT pk_cmn_parx;
       iis            iis    false    797            =           2606    23193    cmn_paymenttp pk_cmn_paymenttp 
   CONSTRAINT     Y   ALTER TABLE ONLY iis.cmn_paymenttp
    ADD CONSTRAINT pk_cmn_paymenttp PRIMARY KEY (id);
 E   ALTER TABLE ONLY iis.cmn_paymenttp DROP CONSTRAINT pk_cmn_paymenttp;
       iis            iis    false    799            ?           2606    23195     cmn_paymenttpx pk_cmn_paymenttpx 
   CONSTRAINT     [   ALTER TABLE ONLY iis.cmn_paymenttpx
    ADD CONSTRAINT pk_cmn_paymenttpx PRIMARY KEY (id);
 G   ALTER TABLE ONLY iis.cmn_paymenttpx DROP CONSTRAINT pk_cmn_paymenttpx;
       iis            iis    false    800                       2606    23197     tic_seattpatts pk_cmn_seattpatts 
   CONSTRAINT     [   ALTER TABLE ONLY iis.tic_seattpatts
    ADD CONSTRAINT pk_cmn_seattpatts PRIMARY KEY (id);
 G   ALTER TABLE ONLY iis.tic_seattpatts DROP CONSTRAINT pk_cmn_seattpatts;
       iis            iis    false    931            B           2606    23199    cmn_site pk_cmn_site 
   CONSTRAINT     O   ALTER TABLE ONLY iis.cmn_site
    ADD CONSTRAINT pk_cmn_site PRIMARY KEY (id);
 ;   ALTER TABLE ONLY iis.cmn_site DROP CONSTRAINT pk_cmn_site;
       iis            iis    false    802            E           2606    23201    cmn_tax pk_cmn_tax 
   CONSTRAINT     M   ALTER TABLE ONLY iis.cmn_tax
    ADD CONSTRAINT pk_cmn_tax PRIMARY KEY (id);
 9   ALTER TABLE ONLY iis.cmn_tax DROP CONSTRAINT pk_cmn_tax;
       iis            iis    false    803            G           2606    23203    cmn_taxrate pk_cmn_taxrate 
   CONSTRAINT     U   ALTER TABLE ONLY iis.cmn_taxrate
    ADD CONSTRAINT pk_cmn_taxrate PRIMARY KEY (id);
 A   ALTER TABLE ONLY iis.cmn_taxrate DROP CONSTRAINT pk_cmn_taxrate;
       iis            iis    false    804            I           2606    23205    cmn_taxx pk_cmn_taxx 
   CONSTRAINT     O   ALTER TABLE ONLY iis.cmn_taxx
    ADD CONSTRAINT pk_cmn_taxx PRIMARY KEY (id);
 ;   ALTER TABLE ONLY iis.cmn_taxx DROP CONSTRAINT pk_cmn_taxx;
       iis            iis    false    805            L           2606    23207    cmn_terr pk_cmn_terr 
   CONSTRAINT     O   ALTER TABLE ONLY iis.cmn_terr
    ADD CONSTRAINT pk_cmn_terr PRIMARY KEY (id);
 ;   ALTER TABLE ONLY iis.cmn_terr DROP CONSTRAINT pk_cmn_terr;
       iis            iis    false    807            O           2606    23209    cmn_terratt pk_cmn_terratt 
   CONSTRAINT     U   ALTER TABLE ONLY iis.cmn_terratt
    ADD CONSTRAINT pk_cmn_terratt PRIMARY KEY (id);
 A   ALTER TABLE ONLY iis.cmn_terratt DROP CONSTRAINT pk_cmn_terratt;
       iis            iis    false    808            Q           2606    23211    cmn_terratts pk_cmn_terratts 
   CONSTRAINT     W   ALTER TABLE ONLY iis.cmn_terratts
    ADD CONSTRAINT pk_cmn_terratts PRIMARY KEY (id);
 C   ALTER TABLE ONLY iis.cmn_terratts DROP CONSTRAINT pk_cmn_terratts;
       iis            iis    false    809            S           2606    23213    cmn_terrattx pk_cmn_terrattx 
   CONSTRAINT     W   ALTER TABLE ONLY iis.cmn_terrattx
    ADD CONSTRAINT pk_cmn_terrattx PRIMARY KEY (id);
 C   ALTER TABLE ONLY iis.cmn_terrattx DROP CONSTRAINT pk_cmn_terrattx;
       iis            iis    false    810            U           2606    23215    cmn_terrlink pk_cmn_terrlink 
   CONSTRAINT     W   ALTER TABLE ONLY iis.cmn_terrlink
    ADD CONSTRAINT pk_cmn_terrlink PRIMARY KEY (id);
 C   ALTER TABLE ONLY iis.cmn_terrlink DROP CONSTRAINT pk_cmn_terrlink;
       iis            iis    false    812            X           2606    23217     cmn_terrlinktp pk_cmn_terrlinktp 
   CONSTRAINT     [   ALTER TABLE ONLY iis.cmn_terrlinktp
    ADD CONSTRAINT pk_cmn_terrlinktp PRIMARY KEY (id);
 G   ALTER TABLE ONLY iis.cmn_terrlinktp DROP CONSTRAINT pk_cmn_terrlinktp;
       iis            iis    false    813            Z           2606    23219 "   cmn_terrlinktpx pk_cmn_terrlinktpx 
   CONSTRAINT     ]   ALTER TABLE ONLY iis.cmn_terrlinktpx
    ADD CONSTRAINT pk_cmn_terrlinktpx PRIMARY KEY (id);
 I   ALTER TABLE ONLY iis.cmn_terrlinktpx DROP CONSTRAINT pk_cmn_terrlinktpx;
       iis            iis    false    814            \           2606    23221    cmn_terrloc pk_cmn_terrloc 
   CONSTRAINT     U   ALTER TABLE ONLY iis.cmn_terrloc
    ADD CONSTRAINT pk_cmn_terrloc PRIMARY KEY (id);
 A   ALTER TABLE ONLY iis.cmn_terrloc DROP CONSTRAINT pk_cmn_terrloc;
       iis            iis    false    816            _           2606    23223    cmn_terrtp pk_cmn_terrtp 
   CONSTRAINT     S   ALTER TABLE ONLY iis.cmn_terrtp
    ADD CONSTRAINT pk_cmn_terrtp PRIMARY KEY (id);
 ?   ALTER TABLE ONLY iis.cmn_terrtp DROP CONSTRAINT pk_cmn_terrtp;
       iis            iis    false    817            a           2606    23225    cmn_terrtpx pk_cmn_terrtpx 
   CONSTRAINT     U   ALTER TABLE ONLY iis.cmn_terrtpx
    ADD CONSTRAINT pk_cmn_terrtpx PRIMARY KEY (id);
 A   ALTER TABLE ONLY iis.cmn_terrtpx DROP CONSTRAINT pk_cmn_terrtpx;
       iis            iis    false    818            c           2606    23227    cmn_terrx pk_cmn_terrx 
   CONSTRAINT     Q   ALTER TABLE ONLY iis.cmn_terrx
    ADD CONSTRAINT pk_cmn_terrx PRIMARY KEY (id);
 =   ALTER TABLE ONLY iis.cmn_terrx DROP CONSTRAINT pk_cmn_terrx;
       iis            iis    false    820            f           2606    23229    cmn_tgp pk_cmn_tgp 
   CONSTRAINT     M   ALTER TABLE ONLY iis.cmn_tgp
    ADD CONSTRAINT pk_cmn_tgp PRIMARY KEY (id);
 9   ALTER TABLE ONLY iis.cmn_tgp DROP CONSTRAINT pk_cmn_tgp;
       iis            iis    false    822            h           2606    23231    cmn_tgptax pk_cmn_tgptax 
   CONSTRAINT     S   ALTER TABLE ONLY iis.cmn_tgptax
    ADD CONSTRAINT pk_cmn_tgptax PRIMARY KEY (id);
 ?   ALTER TABLE ONLY iis.cmn_tgptax DROP CONSTRAINT pk_cmn_tgptax;
       iis            iis    false    823            j           2606    23233    cmn_tgpx pk_cmn_tgpx 
   CONSTRAINT     O   ALTER TABLE ONLY iis.cmn_tgpx
    ADD CONSTRAINT pk_cmn_tgpx PRIMARY KEY (id);
 ;   ALTER TABLE ONLY iis.cmn_tgpx DROP CONSTRAINT pk_cmn_tgpx;
       iis            iis    false    824            m           2606    23235    cmn_um pk_cmn_um 
   CONSTRAINT     K   ALTER TABLE ONLY iis.cmn_um
    ADD CONSTRAINT pk_cmn_um PRIMARY KEY (id);
 7   ALTER TABLE ONLY iis.cmn_um DROP CONSTRAINT pk_cmn_um;
       iis            iis    false    826            o           2606    23237    cmn_umparity pk_cmn_umparity 
   CONSTRAINT     W   ALTER TABLE ONLY iis.cmn_umparity
    ADD CONSTRAINT pk_cmn_umparity PRIMARY KEY (id);
 C   ALTER TABLE ONLY iis.cmn_umparity DROP CONSTRAINT pk_cmn_umparity;
       iis            iis    false    827            q           2606    23239    cmn_umx pk_cmn_umx 
   CONSTRAINT     M   ALTER TABLE ONLY iis.cmn_umx
    ADD CONSTRAINT pk_cmn_umx PRIMARY KEY (id);
 9   ALTER TABLE ONLY iis.cmn_umx DROP CONSTRAINT pk_cmn_umx;
       iis            iis    false    828            u           2606    23241    tic_agenda pk_tic_agenda 
   CONSTRAINT     S   ALTER TABLE ONLY iis.tic_agenda
    ADD CONSTRAINT pk_tic_agenda PRIMARY KEY (id);
 ?   ALTER TABLE ONLY iis.tic_agenda DROP CONSTRAINT pk_tic_agenda;
       iis            iis    false    833            w           2606    23243    tic_agendatp pk_tic_agendatp 
   CONSTRAINT     W   ALTER TABLE ONLY iis.tic_agendatp
    ADD CONSTRAINT pk_tic_agendatp PRIMARY KEY (id);
 C   ALTER TABLE ONLY iis.tic_agendatp DROP CONSTRAINT pk_tic_agendatp;
       iis            iis    false    834            y           2606    23245    tic_agendatpx pk_tic_agendatpx 
   CONSTRAINT     Y   ALTER TABLE ONLY iis.tic_agendatpx
    ADD CONSTRAINT pk_tic_agendatpx PRIMARY KEY (id);
 E   ALTER TABLE ONLY iis.tic_agendatpx DROP CONSTRAINT pk_tic_agendatpx;
       iis            iis    false    835            {           2606    23247    tic_agendax pk_tic_agendax 
   CONSTRAINT     U   ALTER TABLE ONLY iis.tic_agendax
    ADD CONSTRAINT pk_tic_agendax PRIMARY KEY (id);
 A   ALTER TABLE ONLY iis.tic_agendax DROP CONSTRAINT pk_tic_agendax;
       iis            iis    false    837            }           2606    23249    tic_art pk_tic_art 
   CONSTRAINT     M   ALTER TABLE ONLY iis.tic_art
    ADD CONSTRAINT pk_tic_art PRIMARY KEY (id);
 9   ALTER TABLE ONLY iis.tic_art DROP CONSTRAINT pk_tic_art;
       iis            iis    false    839                       2606    23251    tic_artcena pk_tic_artcena 
   CONSTRAINT     U   ALTER TABLE ONLY iis.tic_artcena
    ADD CONSTRAINT pk_tic_artcena PRIMARY KEY (id);
 A   ALTER TABLE ONLY iis.tic_artcena DROP CONSTRAINT pk_tic_artcena;
       iis            iis    false    840            �           2606    23253    tic_artgrp pk_tic_artgrp 
   CONSTRAINT     S   ALTER TABLE ONLY iis.tic_artgrp
    ADD CONSTRAINT pk_tic_artgrp PRIMARY KEY (id);
 ?   ALTER TABLE ONLY iis.tic_artgrp DROP CONSTRAINT pk_tic_artgrp;
       iis            iis    false    841            �           2606    23255    tic_artgrpx pk_tic_artgrpx 
   CONSTRAINT     U   ALTER TABLE ONLY iis.tic_artgrpx
    ADD CONSTRAINT pk_tic_artgrpx PRIMARY KEY (id);
 A   ALTER TABLE ONLY iis.tic_artgrpx DROP CONSTRAINT pk_tic_artgrpx;
       iis            iis    false    842            �           2606    23257    tic_artlink pk_tic_artlink 
   CONSTRAINT     U   ALTER TABLE ONLY iis.tic_artlink
    ADD CONSTRAINT pk_tic_artlink PRIMARY KEY (id);
 A   ALTER TABLE ONLY iis.tic_artlink DROP CONSTRAINT pk_tic_artlink;
       iis            iis    false    844            �           2606    23259 $   tic_artprivilege pk_tic_artprivilege 
   CONSTRAINT     _   ALTER TABLE ONLY iis.tic_artprivilege
    ADD CONSTRAINT pk_tic_artprivilege PRIMARY KEY (id);
 K   ALTER TABLE ONLY iis.tic_artprivilege DROP CONSTRAINT pk_tic_artprivilege;
       iis            iis    false    846            �           2606    23261    tic_artloc pk_tic_artseat 
   CONSTRAINT     T   ALTER TABLE ONLY iis.tic_artloc
    ADD CONSTRAINT pk_tic_artseat PRIMARY KEY (id);
 @   ALTER TABLE ONLY iis.tic_artloc DROP CONSTRAINT pk_tic_artseat;
       iis            iis    false    845            �           2606    23263    tic_arttax pk_tic_arttax 
   CONSTRAINT     S   ALTER TABLE ONLY iis.tic_arttax
    ADD CONSTRAINT pk_tic_arttax PRIMARY KEY (id);
 ?   ALTER TABLE ONLY iis.tic_arttax DROP CONSTRAINT pk_tic_arttax;
       iis            iis    false    847            �           2606    23265    tic_arttp pk_tic_arttp 
   CONSTRAINT     Q   ALTER TABLE ONLY iis.tic_arttp
    ADD CONSTRAINT pk_tic_arttp PRIMARY KEY (id);
 =   ALTER TABLE ONLY iis.tic_arttp DROP CONSTRAINT pk_tic_arttp;
       iis            iis    false    848            �           2606    23267    tic_arttpx pk_tic_arttpx 
   CONSTRAINT     S   ALTER TABLE ONLY iis.tic_arttpx
    ADD CONSTRAINT pk_tic_arttpx PRIMARY KEY (id);
 ?   ALTER TABLE ONLY iis.tic_arttpx DROP CONSTRAINT pk_tic_arttpx;
       iis            iis    false    849            �           2606    23269    tic_artx pk_tic_artx 
   CONSTRAINT     O   ALTER TABLE ONLY iis.tic_artx
    ADD CONSTRAINT pk_tic_artx PRIMARY KEY (id);
 ;   ALTER TABLE ONLY iis.tic_artx DROP CONSTRAINT pk_tic_artx;
       iis            iis    false    851            �           2606    23271    tic_cena pk_tic_cena 
   CONSTRAINT     O   ALTER TABLE ONLY iis.tic_cena
    ADD CONSTRAINT pk_tic_cena PRIMARY KEY (id);
 ;   ALTER TABLE ONLY iis.tic_cena DROP CONSTRAINT pk_tic_cena;
       iis            iis    false    853            �           2606    23273    tic_cenatp pk_tic_cenatp 
   CONSTRAINT     S   ALTER TABLE ONLY iis.tic_cenatp
    ADD CONSTRAINT pk_tic_cenatp PRIMARY KEY (id);
 ?   ALTER TABLE ONLY iis.tic_cenatp DROP CONSTRAINT pk_tic_cenatp;
       iis            iis    false    854            �           2606    23275    tic_cenatpx pk_tic_cenatpx 
   CONSTRAINT     U   ALTER TABLE ONLY iis.tic_cenatpx
    ADD CONSTRAINT pk_tic_cenatpx PRIMARY KEY (id);
 A   ALTER TABLE ONLY iis.tic_cenatpx DROP CONSTRAINT pk_tic_cenatpx;
       iis            iis    false    855            �           2606    23277    tic_cenax pk_tic_cenax 
   CONSTRAINT     Q   ALTER TABLE ONLY iis.tic_cenax
    ADD CONSTRAINT pk_tic_cenax PRIMARY KEY (id);
 =   ALTER TABLE ONLY iis.tic_cenax DROP CONSTRAINT pk_tic_cenax;
       iis            iis    false    857            �           2606    23279 (   tic_chanellseatloc pk_tic_chanellseatloc 
   CONSTRAINT     c   ALTER TABLE ONLY iis.tic_chanellseatloc
    ADD CONSTRAINT pk_tic_chanellseatloc PRIMARY KEY (id);
 O   ALTER TABLE ONLY iis.tic_chanellseatloc DROP CONSTRAINT pk_tic_chanellseatloc;
       iis            iis    false    859            �           2606    23281    tic_channel pk_tic_channel 
   CONSTRAINT     U   ALTER TABLE ONLY iis.tic_channel
    ADD CONSTRAINT pk_tic_channel PRIMARY KEY (id);
 A   ALTER TABLE ONLY iis.tic_channel DROP CONSTRAINT pk_tic_channel;
       iis            iis    false    860            �           2606    23283 *   tic_channeleventpar pk_tic_channeleventpar 
   CONSTRAINT     e   ALTER TABLE ONLY iis.tic_channeleventpar
    ADD CONSTRAINT pk_tic_channeleventpar PRIMARY KEY (id);
 Q   ALTER TABLE ONLY iis.tic_channeleventpar DROP CONSTRAINT pk_tic_channeleventpar;
       iis            iis    false    861            �           2606    23285    tic_channelx pk_tic_channelx 
   CONSTRAINT     W   ALTER TABLE ONLY iis.tic_channelx
    ADD CONSTRAINT pk_tic_channelx PRIMARY KEY (id);
 C   ALTER TABLE ONLY iis.tic_channelx DROP CONSTRAINT pk_tic_channelx;
       iis            iis    false    862            �           2606    23287    tic_condtp pk_tic_condtp 
   CONSTRAINT     S   ALTER TABLE ONLY iis.tic_condtp
    ADD CONSTRAINT pk_tic_condtp PRIMARY KEY (id);
 ?   ALTER TABLE ONLY iis.tic_condtp DROP CONSTRAINT pk_tic_condtp;
       iis            iis    false    863            �           2606    23289    tic_condtpx pk_tic_condtpx 
   CONSTRAINT     U   ALTER TABLE ONLY iis.tic_condtpx
    ADD CONSTRAINT pk_tic_condtpx PRIMARY KEY (id);
 A   ALTER TABLE ONLY iis.tic_condtpx DROP CONSTRAINT pk_tic_condtpx;
       iis            iis    false    864            �           2606    23291    tic_discount pk_tic_discount 
   CONSTRAINT     W   ALTER TABLE ONLY iis.tic_discount
    ADD CONSTRAINT pk_tic_discount PRIMARY KEY (id);
 C   ALTER TABLE ONLY iis.tic_discount DROP CONSTRAINT pk_tic_discount;
       iis            iis    false    866            �           2606    23293     tic_discounttp pk_tic_discounttp 
   CONSTRAINT     [   ALTER TABLE ONLY iis.tic_discounttp
    ADD CONSTRAINT pk_tic_discounttp PRIMARY KEY (id);
 G   ALTER TABLE ONLY iis.tic_discounttp DROP CONSTRAINT pk_tic_discounttp;
       iis            iis    false    867            �           2606    23295 "   tic_discounttpx pk_tic_discounttpx 
   CONSTRAINT     ]   ALTER TABLE ONLY iis.tic_discounttpx
    ADD CONSTRAINT pk_tic_discounttpx PRIMARY KEY (id);
 I   ALTER TABLE ONLY iis.tic_discounttpx DROP CONSTRAINT pk_tic_discounttpx;
       iis            iis    false    868            �           2606    23297    tic_discountx pk_tic_discountx 
   CONSTRAINT     Y   ALTER TABLE ONLY iis.tic_discountx
    ADD CONSTRAINT pk_tic_discountx PRIMARY KEY (id);
 E   ALTER TABLE ONLY iis.tic_discountx DROP CONSTRAINT pk_tic_discountx;
       iis            iis    false    870            #           2606    23299    tmp_tic_doc pk_tic_doc 
   CONSTRAINT     Q   ALTER TABLE ONLY iis.tmp_tic_doc
    ADD CONSTRAINT pk_tic_doc PRIMARY KEY (id);
 =   ALTER TABLE ONLY iis.tmp_tic_doc DROP CONSTRAINT pk_tic_doc;
       iis            iis    false    945            �           2606    23301    tic_docb pk_tic_docb 
   CONSTRAINT     O   ALTER TABLE ONLY iis.tic_docb
    ADD CONSTRAINT pk_tic_docb PRIMARY KEY (id);
 ;   ALTER TABLE ONLY iis.tic_docb DROP CONSTRAINT pk_tic_docb;
       iis            iis    false    873            �           2606    23303 "   tic_docdelivery pk_tic_docdelivery 
   CONSTRAINT     ]   ALTER TABLE ONLY iis.tic_docdelivery
    ADD CONSTRAINT pk_tic_docdelivery PRIMARY KEY (id);
 I   ALTER TABLE ONLY iis.tic_docdelivery DROP CONSTRAINT pk_tic_docdelivery;
       iis            postgres    false    874            �           2606    23305 "   tic_docdocslink pk_tic_docdocslink 
   CONSTRAINT     ]   ALTER TABLE ONLY iis.tic_docdocslink
    ADD CONSTRAINT pk_tic_docdocslink PRIMARY KEY (id);
 I   ALTER TABLE ONLY iis.tic_docdocslink DROP CONSTRAINT pk_tic_docdocslink;
       iis            iis    false    875            �           2606    23307    tic_doclink pk_tic_doclink 
   CONSTRAINT     U   ALTER TABLE ONLY iis.tic_doclink
    ADD CONSTRAINT pk_tic_doclink PRIMARY KEY (id);
 A   ALTER TABLE ONLY iis.tic_doclink DROP CONSTRAINT pk_tic_doclink;
       iis            iis    false    876            �           2606    23309     tic_docpayment pk_tic_docpayment 
   CONSTRAINT     [   ALTER TABLE ONLY iis.tic_docpayment
    ADD CONSTRAINT pk_tic_docpayment PRIMARY KEY (id);
 G   ALTER TABLE ONLY iis.tic_docpayment DROP CONSTRAINT pk_tic_docpayment;
       iis            iis    false    877            �           2606    23311    tic_docslink pk_tic_docslink 
   CONSTRAINT     W   ALTER TABLE ONLY iis.tic_docslink
    ADD CONSTRAINT pk_tic_docslink PRIMARY KEY (id);
 C   ALTER TABLE ONLY iis.tic_docslink DROP CONSTRAINT pk_tic_docslink;
       iis            iis    false    879            �           2606    23313    tic_docsuid pk_tic_docsuid 
   CONSTRAINT     U   ALTER TABLE ONLY iis.tic_docsuid
    ADD CONSTRAINT pk_tic_docsuid PRIMARY KEY (id);
 A   ALTER TABLE ONLY iis.tic_docsuid DROP CONSTRAINT pk_tic_docsuid;
       iis            postgres    false    880            �           2606    23315    tic_doctp pk_tic_doctp 
   CONSTRAINT     Q   ALTER TABLE ONLY iis.tic_doctp
    ADD CONSTRAINT pk_tic_doctp PRIMARY KEY (id);
 =   ALTER TABLE ONLY iis.tic_doctp DROP CONSTRAINT pk_tic_doctp;
       iis            iis    false    740            �           2606    23317    tic_doctpx pk_tic_doctpx 
   CONSTRAINT     S   ALTER TABLE ONLY iis.tic_doctpx
    ADD CONSTRAINT pk_tic_doctpx PRIMARY KEY (id);
 ?   ALTER TABLE ONLY iis.tic_doctpx DROP CONSTRAINT pk_tic_doctpx;
       iis            iis    false    741            �           2606    23319    tic_docvr pk_tic_docvr 
   CONSTRAINT     Q   ALTER TABLE ONLY iis.tic_docvr
    ADD CONSTRAINT pk_tic_docvr PRIMARY KEY (id);
 =   ALTER TABLE ONLY iis.tic_docvr DROP CONSTRAINT pk_tic_docvr;
       iis            iis    false    882            �           2606    23321    tic_docvrx pk_tic_docvrx 
   CONSTRAINT     S   ALTER TABLE ONLY iis.tic_docvrx
    ADD CONSTRAINT pk_tic_docvrx PRIMARY KEY (id);
 ?   ALTER TABLE ONLY iis.tic_docvrx DROP CONSTRAINT pk_tic_docvrx;
       iis            iis    false    883            �           2606    23323    tic_event pk_tic_event 
   CONSTRAINT     Q   ALTER TABLE ONLY iis.tic_event
    ADD CONSTRAINT pk_tic_event PRIMARY KEY (id);
 =   ALTER TABLE ONLY iis.tic_event DROP CONSTRAINT pk_tic_event;
       iis            iis    false    885            �           2606    23325 "   tic_eventagenda pk_tic_eventagenda 
   CONSTRAINT     ]   ALTER TABLE ONLY iis.tic_eventagenda
    ADD CONSTRAINT pk_tic_eventagenda PRIMARY KEY (id);
 I   ALTER TABLE ONLY iis.tic_eventagenda DROP CONSTRAINT pk_tic_eventagenda;
       iis            iis    false    886            �           2606    23327    tic_eventart pk_tic_eventart 
   CONSTRAINT     W   ALTER TABLE ONLY iis.tic_eventart
    ADD CONSTRAINT pk_tic_eventart PRIMARY KEY (id);
 C   ALTER TABLE ONLY iis.tic_eventart DROP CONSTRAINT pk_tic_eventart;
       iis            iis    false    887            �           2606    23329 $   tic_eventartcena pk_tic_eventartcena 
   CONSTRAINT     _   ALTER TABLE ONLY iis.tic_eventartcena
    ADD CONSTRAINT pk_tic_eventartcena PRIMARY KEY (id);
 K   ALTER TABLE ONLY iis.tic_eventartcena DROP CONSTRAINT pk_tic_eventartcena;
       iis            iis    false    888            �           2606    23331 $   tic_eventartlink pk_tic_eventartlink 
   CONSTRAINT     _   ALTER TABLE ONLY iis.tic_eventartlink
    ADD CONSTRAINT pk_tic_eventartlink PRIMARY KEY (id);
 K   ALTER TABLE ONLY iis.tic_eventartlink DROP CONSTRAINT pk_tic_eventartlink;
       iis            iis    false    889            �           2606    23333 "   tic_eventartloc pk_tic_eventartloc 
   CONSTRAINT     ]   ALTER TABLE ONLY iis.tic_eventartloc
    ADD CONSTRAINT pk_tic_eventartloc PRIMARY KEY (id);
 I   ALTER TABLE ONLY iis.tic_eventartloc DROP CONSTRAINT pk_tic_eventartloc;
       iis            iis    false    890            �           2606    23335    tic_eventatt pk_tic_eventatt 
   CONSTRAINT     W   ALTER TABLE ONLY iis.tic_eventatt
    ADD CONSTRAINT pk_tic_eventatt PRIMARY KEY (id);
 C   ALTER TABLE ONLY iis.tic_eventatt DROP CONSTRAINT pk_tic_eventatt;
       iis            iis    false    891            �           2606    23337    tic_eventatts pk_tic_eventatts 
   CONSTRAINT     Y   ALTER TABLE ONLY iis.tic_eventatts
    ADD CONSTRAINT pk_tic_eventatts PRIMARY KEY (id);
 E   ALTER TABLE ONLY iis.tic_eventatts DROP CONSTRAINT pk_tic_eventatts;
       iis            iis    false    892            �           2606    23339     tic_eventatttp pk_tic_eventatttp 
   CONSTRAINT     [   ALTER TABLE ONLY iis.tic_eventatttp
    ADD CONSTRAINT pk_tic_eventatttp PRIMARY KEY (id);
 G   ALTER TABLE ONLY iis.tic_eventatttp DROP CONSTRAINT pk_tic_eventatttp;
       iis            postgres    false    893            �           2606    23341 "   tic_eventatttpx pk_tic_eventatttpx 
   CONSTRAINT     ]   ALTER TABLE ONLY iis.tic_eventatttpx
    ADD CONSTRAINT pk_tic_eventatttpx PRIMARY KEY (id);
 I   ALTER TABLE ONLY iis.tic_eventatttpx DROP CONSTRAINT pk_tic_eventatttpx;
       iis            postgres    false    894            �           2606    23343    tic_eventattx pk_tic_eventattx 
   CONSTRAINT     Y   ALTER TABLE ONLY iis.tic_eventattx
    ADD CONSTRAINT pk_tic_eventattx PRIMARY KEY (id);
 E   ALTER TABLE ONLY iis.tic_eventattx DROP CONSTRAINT pk_tic_eventattx;
       iis            iis    false    896            �           2606    23345 "   tic_eventcenatp pk_tic_eventcenatp 
   CONSTRAINT     ]   ALTER TABLE ONLY iis.tic_eventcenatp
    ADD CONSTRAINT pk_tic_eventcenatp PRIMARY KEY (id);
 I   ALTER TABLE ONLY iis.tic_eventcenatp DROP CONSTRAINT pk_tic_eventcenatp;
       iis            iis    false    898            �           2606    23347    tic_eventctg pk_tic_eventctg 
   CONSTRAINT     W   ALTER TABLE ONLY iis.tic_eventctg
    ADD CONSTRAINT pk_tic_eventctg PRIMARY KEY (id);
 C   ALTER TABLE ONLY iis.tic_eventctg DROP CONSTRAINT pk_tic_eventctg;
       iis            iis    false    899            �           2606    23349    tic_eventctgx pk_tic_eventctgx 
   CONSTRAINT     Y   ALTER TABLE ONLY iis.tic_eventctgx
    ADD CONSTRAINT pk_tic_eventctgx PRIMARY KEY (id);
 E   ALTER TABLE ONLY iis.tic_eventctgx DROP CONSTRAINT pk_tic_eventctgx;
       iis            iis    false    900            �           2606    23351    tic_eventlink pk_tic_eventlink 
   CONSTRAINT     Y   ALTER TABLE ONLY iis.tic_eventlink
    ADD CONSTRAINT pk_tic_eventlink PRIMARY KEY (id);
 E   ALTER TABLE ONLY iis.tic_eventlink DROP CONSTRAINT pk_tic_eventlink;
       iis            iis    false    902            �           2606    23353    tic_eventloc pk_tic_eventloc 
   CONSTRAINT     W   ALTER TABLE ONLY iis.tic_eventloc
    ADD CONSTRAINT pk_tic_eventloc PRIMARY KEY (id);
 C   ALTER TABLE ONLY iis.tic_eventloc DROP CONSTRAINT pk_tic_eventloc;
       iis            iis    false    903            �           2606    23355    tic_eventobj pk_tic_eventobj 
   CONSTRAINT     W   ALTER TABLE ONLY iis.tic_eventobj
    ADD CONSTRAINT pk_tic_eventobj PRIMARY KEY (id);
 C   ALTER TABLE ONLY iis.tic_eventobj DROP CONSTRAINT pk_tic_eventobj;
       iis            iis    false    904            �           2606    23357    tic_events pk_tic_events 
   CONSTRAINT     S   ALTER TABLE ONLY iis.tic_events
    ADD CONSTRAINT pk_tic_events PRIMARY KEY (id);
 ?   ALTER TABLE ONLY iis.tic_events DROP CONSTRAINT pk_tic_events;
       iis            iis    false    905            �           2606    23359    tic_eventst pk_tic_eventst 
   CONSTRAINT     U   ALTER TABLE ONLY iis.tic_eventst
    ADD CONSTRAINT pk_tic_eventst PRIMARY KEY (id);
 A   ALTER TABLE ONLY iis.tic_eventst DROP CONSTRAINT pk_tic_eventst;
       iis            iis    false    906            �           2606    23361    tic_eventtp pk_tic_eventtp 
   CONSTRAINT     U   ALTER TABLE ONLY iis.tic_eventtp
    ADD CONSTRAINT pk_tic_eventtp PRIMARY KEY (id);
 A   ALTER TABLE ONLY iis.tic_eventtp DROP CONSTRAINT pk_tic_eventtp;
       iis            iis    false    907            �           2606    23363    tic_eventtps pk_tic_eventtps 
   CONSTRAINT     W   ALTER TABLE ONLY iis.tic_eventtps
    ADD CONSTRAINT pk_tic_eventtps PRIMARY KEY (id);
 C   ALTER TABLE ONLY iis.tic_eventtps DROP CONSTRAINT pk_tic_eventtps;
       iis            iis    false    908            �           2606    23365    tic_eventtpx pk_tic_eventtpx 
   CONSTRAINT     W   ALTER TABLE ONLY iis.tic_eventtpx
    ADD CONSTRAINT pk_tic_eventtpx PRIMARY KEY (id);
 C   ALTER TABLE ONLY iis.tic_eventtpx DROP CONSTRAINT pk_tic_eventtpx;
       iis            iis    false    909            �           2606    23367    tic_eventx pk_tic_eventx 
   CONSTRAINT     S   ALTER TABLE ONLY iis.tic_eventx
    ADD CONSTRAINT pk_tic_eventx PRIMARY KEY (id);
 ?   ALTER TABLE ONLY iis.tic_eventx DROP CONSTRAINT pk_tic_eventx;
       iis            iis    false    911            �           2606    23369 $   tic_parprivilege pk_tic_parprivilege 
   CONSTRAINT     _   ALTER TABLE ONLY iis.tic_parprivilege
    ADD CONSTRAINT pk_tic_parprivilege PRIMARY KEY (id);
 K   ALTER TABLE ONLY iis.tic_parprivilege DROP CONSTRAINT pk_tic_parprivilege;
       iis            iis    false    913            �           2606    23371    tic_paycard pk_tic_paycard 
   CONSTRAINT     U   ALTER TABLE ONLY iis.tic_paycard
    ADD CONSTRAINT pk_tic_paycard PRIMARY KEY (id);
 A   ALTER TABLE ONLY iis.tic_paycard DROP CONSTRAINT pk_tic_paycard;
       iis            iis    false    914            �           2606    23373    tic_privilege pk_tic_privilege 
   CONSTRAINT     Y   ALTER TABLE ONLY iis.tic_privilege
    ADD CONSTRAINT pk_tic_privilege PRIMARY KEY (id);
 E   ALTER TABLE ONLY iis.tic_privilege DROP CONSTRAINT pk_tic_privilege;
       iis            iis    false    915            �           2606    23375 &   tic_privilegecond pk_tic_privilegecond 
   CONSTRAINT     a   ALTER TABLE ONLY iis.tic_privilegecond
    ADD CONSTRAINT pk_tic_privilegecond PRIMARY KEY (id);
 M   ALTER TABLE ONLY iis.tic_privilegecond DROP CONSTRAINT pk_tic_privilegecond;
       iis            iis    false    916            �           2606    23377 .   tic_privilegediscount pk_tic_privilegediscount 
   CONSTRAINT     i   ALTER TABLE ONLY iis.tic_privilegediscount
    ADD CONSTRAINT pk_tic_privilegediscount PRIMARY KEY (id);
 U   ALTER TABLE ONLY iis.tic_privilegediscount DROP CONSTRAINT pk_tic_privilegediscount;
       iis            iis    false    917            �           2606    23379 &   tic_privilegelink pk_tic_privilegelink 
   CONSTRAINT     a   ALTER TABLE ONLY iis.tic_privilegelink
    ADD CONSTRAINT pk_tic_privilegelink PRIMARY KEY (id);
 M   ALTER TABLE ONLY iis.tic_privilegelink DROP CONSTRAINT pk_tic_privilegelink;
       iis            iis    false    918            �           2606    23381 "   tic_privilegetp pk_tic_privilegetp 
   CONSTRAINT     ]   ALTER TABLE ONLY iis.tic_privilegetp
    ADD CONSTRAINT pk_tic_privilegetp PRIMARY KEY (id);
 I   ALTER TABLE ONLY iis.tic_privilegetp DROP CONSTRAINT pk_tic_privilegetp;
       iis            iis    false    919                       2606    23383 $   tic_privilegetpx pk_tic_privilegetpx 
   CONSTRAINT     _   ALTER TABLE ONLY iis.tic_privilegetpx
    ADD CONSTRAINT pk_tic_privilegetpx PRIMARY KEY (id);
 K   ALTER TABLE ONLY iis.tic_privilegetpx DROP CONSTRAINT pk_tic_privilegetpx;
       iis            iis    false    920                       2606    23385     tic_privilegex pk_tic_privilegex 
   CONSTRAINT     [   ALTER TABLE ONLY iis.tic_privilegex
    ADD CONSTRAINT pk_tic_privilegex PRIMARY KEY (id);
 G   ALTER TABLE ONLY iis.tic_privilegex DROP CONSTRAINT pk_tic_privilegex;
       iis            iis    false    922                       2606    23387    tic_season pk_tic_season 
   CONSTRAINT     S   ALTER TABLE ONLY iis.tic_season
    ADD CONSTRAINT pk_tic_season PRIMARY KEY (id);
 ?   ALTER TABLE ONLY iis.tic_season DROP CONSTRAINT pk_tic_season;
       iis            iis    false    924                       2606    23389    tic_seasonx pk_tic_seasonx 
   CONSTRAINT     U   ALTER TABLE ONLY iis.tic_seasonx
    ADD CONSTRAINT pk_tic_seasonx PRIMARY KEY (id);
 A   ALTER TABLE ONLY iis.tic_seasonx DROP CONSTRAINT pk_tic_seasonx;
       iis            iis    false    925            	           2606    23391    tic_seat pk_tic_seat 
   CONSTRAINT     O   ALTER TABLE ONLY iis.tic_seat
    ADD CONSTRAINT pk_tic_seat PRIMARY KEY (id);
 ;   ALTER TABLE ONLY iis.tic_seat DROP CONSTRAINT pk_tic_seat;
       iis            iis    false    927                       2606    23393    tic_seatloc pk_tic_seatloc 
   CONSTRAINT     U   ALTER TABLE ONLY iis.tic_seatloc
    ADD CONSTRAINT pk_tic_seatloc PRIMARY KEY (id);
 A   ALTER TABLE ONLY iis.tic_seatloc DROP CONSTRAINT pk_tic_seatloc;
       iis            iis    false    928                       2606    23395    tic_seattp pk_tic_seattp 
   CONSTRAINT     S   ALTER TABLE ONLY iis.tic_seattp
    ADD CONSTRAINT pk_tic_seattp PRIMARY KEY (id);
 ?   ALTER TABLE ONLY iis.tic_seattp DROP CONSTRAINT pk_tic_seattp;
       iis            iis    false    929                       2606    23397    tic_seattpatt pk_tic_seattpatt 
   CONSTRAINT     Y   ALTER TABLE ONLY iis.tic_seattpatt
    ADD CONSTRAINT pk_tic_seattpatt PRIMARY KEY (id);
 E   ALTER TABLE ONLY iis.tic_seattpatt DROP CONSTRAINT pk_tic_seattpatt;
       iis            iis    false    930                       2606    23399     tic_seattpattx pk_tic_seattpattx 
   CONSTRAINT     [   ALTER TABLE ONLY iis.tic_seattpattx
    ADD CONSTRAINT pk_tic_seattpattx PRIMARY KEY (id);
 G   ALTER TABLE ONLY iis.tic_seattpattx DROP CONSTRAINT pk_tic_seattpattx;
       iis            iis    false    932                       2606    23401    tic_seattpx pk_tic_seattpx 
   CONSTRAINT     U   ALTER TABLE ONLY iis.tic_seattpx
    ADD CONSTRAINT pk_tic_seattpx PRIMARY KEY (id);
 A   ALTER TABLE ONLY iis.tic_seattpx DROP CONSTRAINT pk_tic_seattpx;
       iis            iis    false    933                       2606    23403    tic_seatx pk_tic_seatx 
   CONSTRAINT     Q   ALTER TABLE ONLY iis.tic_seatx
    ADD CONSTRAINT pk_tic_seatx PRIMARY KEY (id);
 =   ALTER TABLE ONLY iis.tic_seatx DROP CONSTRAINT pk_tic_seatx;
       iis            iis    false    934                       2606    23405    tic_speccheck pk_tic_speccheck 
   CONSTRAINT     Y   ALTER TABLE ONLY iis.tic_speccheck
    ADD CONSTRAINT pk_tic_speccheck PRIMARY KEY (id);
 E   ALTER TABLE ONLY iis.tic_speccheck DROP CONSTRAINT pk_tic_speccheck;
       iis            iis    false    935                       2606    23407    tic_stampa pk_tic_stampa 
   CONSTRAINT     S   ALTER TABLE ONLY iis.tic_stampa
    ADD CONSTRAINT pk_tic_stampa PRIMARY KEY (id);
 ?   ALTER TABLE ONLY iis.tic_stampa DROP CONSTRAINT pk_tic_stampa;
       iis            iis    false    936            �           2606    23409    tic_doc pk_ticdoc 
   CONSTRAINT     L   ALTER TABLE ONLY iis.tic_doc
    ADD CONSTRAINT pk_ticdoc PRIMARY KEY (id);
 8   ALTER TABLE ONLY iis.tic_doc DROP CONSTRAINT pk_ticdoc;
       iis            iis    false    872            �           2606    23411    tic_docs pk_ticdocs 
   CONSTRAINT     N   ALTER TABLE ONLY iis.tic_docs
    ADD CONSTRAINT pk_ticdocs PRIMARY KEY (id);
 :   ALTER TABLE ONLY iis.tic_docs DROP CONSTRAINT pk_ticdocs;
       iis            iis    false    878                       2606    23413    tic_venue_item tic_venue_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY iis.tic_venue_item
    ADD CONSTRAINT tic_venue_pkey PRIMARY KEY (id);
 D   ALTER TABLE ONLY iis.tic_venue_item DROP CONSTRAINT tic_venue_pkey;
       iis            iis    false    942            �           1259    23414    adm_action_ux1    INDEX     I   CREATE UNIQUE INDEX adm_action_ux1 ON iis.adm_action USING btree (code);
    DROP INDEX iis.adm_action_ux1;
       iis            iis    false    702            �           1259    23415    adm_roll_ux1    INDEX     E   CREATE UNIQUE INDEX adm_roll_ux1 ON iis.adm_roll USING btree (code);
    DROP INDEX iis.adm_roll_ux1;
       iis            iis    false    711            �           1259    23416    adm_user_ux1    INDEX     I   CREATE UNIQUE INDEX adm_user_ux1 ON iis.adm_user USING btree (username);
    DROP INDEX iis.adm_user_ux1;
       iis            iis    false    718            �           1259    23417    adm_user_ux2    INDEX     E   CREATE UNIQUE INDEX adm_user_ux2 ON iis.adm_user USING btree (mail);
    DROP INDEX iis.adm_user_ux2;
       iis            iis    false    718            �           1259    23418    adm_usergrp_ux1    INDEX     K   CREATE UNIQUE INDEX adm_usergrp_ux1 ON iis.adm_usergrp USING btree (code);
     DROP INDEX iis.adm_usergrp_ux1;
       iis            iis    false    719            �           1259    23419    cmn_curr_ux1    INDEX     E   CREATE UNIQUE INDEX cmn_curr_ux1 ON iis.cmn_curr USING btree (code);
    DROP INDEX iis.cmn_curr_ux1;
       iis            iis    false    736            �           1259    23420    cmn_link_ux    INDEX     D   CREATE UNIQUE INDEX cmn_link_ux ON iis.cmn_link USING btree (code);
    DROP INDEX iis.cmn_link_ux;
       iis            iis    false    746            �           1259    23421    cmn_loc_ux1    INDEX     C   CREATE UNIQUE INDEX cmn_loc_ux1 ON iis.cmn_loc USING btree (code);
    DROP INDEX iis.cmn_loc_ux1;
       iis            iis    false    749            �           1259    23422    cmn_locatt_ux1    INDEX     I   CREATE UNIQUE INDEX cmn_locatt_ux1 ON iis.cmn_locatt USING btree (code);
    DROP INDEX iis.cmn_locatt_ux1;
       iis            iis    false    750            �           1259    23423    cmn_loclinktp_ux1    INDEX     O   CREATE UNIQUE INDEX cmn_loclinktp_ux1 ON iis.cmn_loclinktp USING btree (code);
 "   DROP INDEX iis.cmn_loclinktp_ux1;
       iis            iis    false    755            �           1259    23424    cmn_loctp_ux1    INDEX     G   CREATE UNIQUE INDEX cmn_loctp_ux1 ON iis.cmn_loctp USING btree (code);
    DROP INDEX iis.cmn_loctp_ux1;
       iis            iis    false    759                       1259    23425    cmn_menu_ux1    INDEX     E   CREATE UNIQUE INDEX cmn_menu_ux1 ON iis.cmn_menu USING btree (code);
    DROP INDEX iis.cmn_menu_ux1;
       iis            iis    false    764                       1259    23426    cmn_module_ux1    INDEX     I   CREATE UNIQUE INDEX cmn_module_ux1 ON iis.cmn_module USING btree (code);
    DROP INDEX iis.cmn_module_ux1;
       iis            iis    false    767            �           1259    23427    cmn_obj_ux1    INDEX     C   CREATE UNIQUE INDEX cmn_obj_ux1 ON iis.cmn_obj USING btree (code);
    DROP INDEX iis.cmn_obj_ux1;
       iis            iis    false    731                       1259    23428    cmn_objatt_ux1    INDEX     I   CREATE UNIQUE INDEX cmn_objatt_ux1 ON iis.cmn_objatt USING btree (code);
    DROP INDEX iis.cmn_objatt_ux1;
       iis            iis    false    770                       1259    23429    cmn_objatttp_ux1    INDEX     M   CREATE UNIQUE INDEX cmn_objatttp_ux1 ON iis.cmn_objatttp USING btree (code);
 !   DROP INDEX iis.cmn_objatttp_ux1;
       iis            iis    false    772                       1259    23430    cmn_objtp_ux1    INDEX     G   CREATE UNIQUE INDEX cmn_objtp_ux1 ON iis.cmn_objtp USING btree (code);
    DROP INDEX iis.cmn_objtp_ux1;
       iis            iis    false    778                        1259    23431    cmn_par_ux1    INDEX     C   CREATE UNIQUE INDEX cmn_par_ux1 ON iis.cmn_par USING btree (code);
    DROP INDEX iis.cmn_par_ux1;
       iis            iis    false    783            %           1259    23432    cmn_paratt_ux1    INDEX     I   CREATE UNIQUE INDEX cmn_paratt_ux1 ON iis.cmn_paratt USING btree (code);
    DROP INDEX iis.cmn_paratt_ux1;
       iis            iis    false    785            .           1259    23433    cmn_parcontacttp_ux1    INDEX     U   CREATE UNIQUE INDEX cmn_parcontacttp_ux1 ON iis.cmn_parcontacttp USING btree (code);
 %   DROP INDEX iis.cmn_parcontacttp_ux1;
       iis            iis    false    790            5           1259    23434    cmn_partp_ux1    INDEX     G   CREATE UNIQUE INDEX cmn_partp_ux1 ON iis.cmn_partp USING btree (code);
    DROP INDEX iis.cmn_partp_ux1;
       iis            iis    false    794            @           1259    23435    cmn_site_ux1    INDEX     E   CREATE UNIQUE INDEX cmn_site_ux1 ON iis.cmn_site USING btree (code);
    DROP INDEX iis.cmn_site_ux1;
       iis            iis    false    802            C           1259    23436    cmn_tax_ux1    INDEX     C   CREATE UNIQUE INDEX cmn_tax_ux1 ON iis.cmn_tax USING btree (code);
    DROP INDEX iis.cmn_tax_ux1;
       iis            iis    false    803            J           1259    23437    cmn_terr_ux1    INDEX     E   CREATE UNIQUE INDEX cmn_terr_ux1 ON iis.cmn_terr USING btree (code);
    DROP INDEX iis.cmn_terr_ux1;
       iis            iis    false    807            M           1259    23438    cmn_terratt_ux1    INDEX     K   CREATE UNIQUE INDEX cmn_terratt_ux1 ON iis.cmn_terratt USING btree (code);
     DROP INDEX iis.cmn_terratt_ux1;
       iis            iis    false    808            V           1259    23439    cmn_terrlinktp_ux1    INDEX     Q   CREATE UNIQUE INDEX cmn_terrlinktp_ux1 ON iis.cmn_terrlinktp USING btree (code);
 #   DROP INDEX iis.cmn_terrlinktp_ux1;
       iis            iis    false    813            ]           1259    23440    cmn_terrtp_ux1    INDEX     I   CREATE UNIQUE INDEX cmn_terrtp_ux1 ON iis.cmn_terrtp USING btree (code);
    DROP INDEX iis.cmn_terrtp_ux1;
       iis            iis    false    817            d           1259    23441    cmn_tgp_ux1    INDEX     C   CREATE UNIQUE INDEX cmn_tgp_ux1 ON iis.cmn_tgp USING btree (code);
    DROP INDEX iis.cmn_tgp_ux1;
       iis            iis    false    822            k           1259    23442 
   cmn_um_ux1    INDEX     A   CREATE UNIQUE INDEX cmn_um_ux1 ON iis.cmn_um USING btree (code);
    DROP INDEX iis.cmn_um_ux1;
       iis            iis    false    826            �           1259    23443    i_fk_cmn_valutakurs1    INDEX     K   CREATE INDEX i_fk_cmn_valutakurs1 ON iis.cmn_currrate USING btree (curr1);
 %   DROP INDEX iis.i_fk_cmn_valutakurs1;
       iis            iis    false    737            �           2620    23444    adm_user set_created_at_trigger    TRIGGER     x   CREATE TRIGGER set_created_at_trigger BEFORE INSERT ON iis.adm_user FOR EACH ROW EXECUTE FUNCTION iis.set_created_at();
 5   DROP TRIGGER set_created_at_trigger ON iis.adm_user;
       iis          iis    false    718    949            �           2620    23445    adm_user set_updated_at_trigger    TRIGGER     x   CREATE TRIGGER set_updated_at_trigger BEFORE UPDATE ON iis.adm_user FOR EACH ROW EXECUTE FUNCTION iis.set_updated_at();
 5   DROP TRIGGER set_updated_at_trigger ON iis.adm_user;
       iis          iis    false    950    718            $           2606    25256    adm_actionx fk_adm_actionx1    FK CONSTRAINT     y   ALTER TABLE ONLY iis.adm_actionx
    ADD CONSTRAINT fk_adm_actionx1 FOREIGN KEY (tableid) REFERENCES iis.adm_action(id);
 B   ALTER TABLE ONLY iis.adm_actionx DROP CONSTRAINT fk_adm_actionx1;
       iis          iis    false    702    7320    703            %           2606    25261    adm_paruser fk_adm_paruser1    FK CONSTRAINT     s   ALTER TABLE ONLY iis.adm_paruser
    ADD CONSTRAINT fk_adm_paruser1 FOREIGN KEY (usr) REFERENCES iis.adm_user(id);
 B   ALTER TABLE ONLY iis.adm_paruser DROP CONSTRAINT fk_adm_paruser1;
       iis          iis    false    710    7351    718            +           2606    25266    adm_rollx fk_adm_rollx1    FK CONSTRAINT     s   ALTER TABLE ONLY iis.adm_rollx
    ADD CONSTRAINT fk_adm_rollx1 FOREIGN KEY (tableid) REFERENCES iis.adm_roll(id);
 >   ALTER TABLE ONLY iis.adm_rollx DROP CONSTRAINT fk_adm_rollx1;
       iis          iis    false    711    715    7335            -           2606    25271    adm_useraddr fk_adm_useraddr1    FK CONSTRAINT     u   ALTER TABLE ONLY iis.adm_useraddr
    ADD CONSTRAINT fk_adm_useraddr1 FOREIGN KEY (usr) REFERENCES iis.adm_user(id);
 D   ALTER TABLE ONLY iis.adm_useraddr DROP CONSTRAINT fk_adm_useraddr1;
       iis          postgres    false    721    718    7351            .           2606    25276    adm_usergrpx fk_adm_usergrpx1    FK CONSTRAINT     |   ALTER TABLE ONLY iis.adm_usergrpx
    ADD CONSTRAINT fk_adm_usergrpx1 FOREIGN KEY (tableid) REFERENCES iis.adm_usergrp(id);
 D   ALTER TABLE ONLY iis.adm_usergrpx DROP CONSTRAINT fk_adm_usergrpx1;
       iis          iis    false    7354    723    719            2           2606    25281    adm_userloc fk_adm_userloc1    FK CONSTRAINT     s   ALTER TABLE ONLY iis.adm_userloc
    ADD CONSTRAINT fk_adm_userloc1 FOREIGN KEY (loc) REFERENCES iis.adm_user(id);
 B   ALTER TABLE ONLY iis.adm_userloc DROP CONSTRAINT fk_adm_userloc1;
       iis          iis    false    718    727    7351            <           2606    25286    cmn_ccardx fk_cmn_ccardx1    FK CONSTRAINT     v   ALTER TABLE ONLY iis.cmn_ccardx
    ADD CONSTRAINT fk_cmn_ccardx1 FOREIGN KEY (tableid) REFERENCES iis.cmn_ccard(id);
 @   ALTER TABLE ONLY iis.cmn_ccardx DROP CONSTRAINT fk_cmn_ccardx1;
       iis          iis    false    7375    734    735            =           2606    25291    cmn_curr fk_cmn_curr1    FK CONSTRAINT     q   ALTER TABLE ONLY iis.cmn_curr
    ADD CONSTRAINT fk_cmn_curr1 FOREIGN KEY (country) REFERENCES iis.cmn_terr(id);
 <   ALTER TABLE ONLY iis.cmn_curr DROP CONSTRAINT fk_cmn_curr1;
       iis          iis    false    807    7500    736            >           2606    25296    cmn_currrate fk_cmn_currrate1    FK CONSTRAINT     w   ALTER TABLE ONLY iis.cmn_currrate
    ADD CONSTRAINT fk_cmn_currrate1 FOREIGN KEY (curr1) REFERENCES iis.cmn_curr(id);
 D   ALTER TABLE ONLY iis.cmn_currrate DROP CONSTRAINT fk_cmn_currrate1;
       iis          iis    false    736    7380    737            ?           2606    25301    cmn_currrate fk_cmn_currrate2    FK CONSTRAINT     w   ALTER TABLE ONLY iis.cmn_currrate
    ADD CONSTRAINT fk_cmn_currrate2 FOREIGN KEY (curr2) REFERENCES iis.cmn_curr(id);
 D   ALTER TABLE ONLY iis.cmn_currrate DROP CONSTRAINT fk_cmn_currrate2;
       iis          iis    false    7380    737    736            @           2606    25306    cmn_currx fk_cmn_currx1    FK CONSTRAINT     s   ALTER TABLE ONLY iis.cmn_currx
    ADD CONSTRAINT fk_cmn_currx1 FOREIGN KEY (tableid) REFERENCES iis.cmn_curr(id);
 >   ALTER TABLE ONLY iis.cmn_currx DROP CONSTRAINT fk_cmn_currx1;
       iis          iis    false    736    7380    738            B           2606    25311    cmn_inputtpx fk_cmn_inputtpx1    FK CONSTRAINT     |   ALTER TABLE ONLY iis.cmn_inputtpx
    ADD CONSTRAINT fk_cmn_inputtpx1 FOREIGN KEY (tableid) REFERENCES iis.cmn_inputtp(id);
 D   ALTER TABLE ONLY iis.cmn_inputtpx DROP CONSTRAINT fk_cmn_inputtpx1;
       iis          iis    false    743    7391    744            ~           2606    25316    cmn_umparity fk_cmn_jmodnos1    FK CONSTRAINT     r   ALTER TABLE ONLY iis.cmn_umparity
    ADD CONSTRAINT fk_cmn_jmodnos1 FOREIGN KEY (um1) REFERENCES iis.cmn_um(id);
 C   ALTER TABLE ONLY iis.cmn_umparity DROP CONSTRAINT fk_cmn_jmodnos1;
       iis          iis    false    7533    826    827                       2606    25321    cmn_umparity fk_cmn_jmodnos2    FK CONSTRAINT     r   ALTER TABLE ONLY iis.cmn_umparity
    ADD CONSTRAINT fk_cmn_jmodnos2 FOREIGN KEY (um2) REFERENCES iis.cmn_um(id);
 C   ALTER TABLE ONLY iis.cmn_umparity DROP CONSTRAINT fk_cmn_jmodnos2;
       iis          iis    false    827    826    7533            C           2606    25326    cmn_link fk_cmn_link1    FK CONSTRAINT     q   ALTER TABLE ONLY iis.cmn_link
    ADD CONSTRAINT fk_cmn_link1 FOREIGN KEY (objtp1) REFERENCES iis.cmn_objtp(id);
 <   ALTER TABLE ONLY iis.cmn_link DROP CONSTRAINT fk_cmn_link1;
       iis          iis    false    7451    778    746            D           2606    25331    cmn_link fk_cmn_link2    FK CONSTRAINT     q   ALTER TABLE ONLY iis.cmn_link
    ADD CONSTRAINT fk_cmn_link2 FOREIGN KEY (objtp2) REFERENCES iis.cmn_objtp(id);
 <   ALTER TABLE ONLY iis.cmn_link DROP CONSTRAINT fk_cmn_link2;
       iis          iis    false    778    746    7451            F           2606    25336    cmn_linkx fk_cmn_linkx1    FK CONSTRAINT     s   ALTER TABLE ONLY iis.cmn_linkx
    ADD CONSTRAINT fk_cmn_linkx1 FOREIGN KEY (tableid) REFERENCES iis.cmn_link(id);
 >   ALTER TABLE ONLY iis.cmn_linkx DROP CONSTRAINT fk_cmn_linkx1;
       iis          iis    false    746    747    7396            G           2606    25341    cmn_loc fk_cmn_loc1    FK CONSTRAINT     k   ALTER TABLE ONLY iis.cmn_loc
    ADD CONSTRAINT fk_cmn_loc1 FOREIGN KEY (tp) REFERENCES iis.cmn_loctp(id);
 :   ALTER TABLE ONLY iis.cmn_loc DROP CONSTRAINT fk_cmn_loc1;
       iis          iis    false    7420    759    749            H           2606    25346    cmn_locatts fk_cmn_locatts1    FK CONSTRAINT     x   ALTER TABLE ONLY iis.cmn_locatts
    ADD CONSTRAINT fk_cmn_locatts1 FOREIGN KEY (locatt) REFERENCES iis.cmn_locatt(id);
 B   ALTER TABLE ONLY iis.cmn_locatts DROP CONSTRAINT fk_cmn_locatts1;
       iis          iis    false    751    750    7404            I           2606    25351    cmn_locatts fk_cmn_locatts2    FK CONSTRAINT     r   ALTER TABLE ONLY iis.cmn_locatts
    ADD CONSTRAINT fk_cmn_locatts2 FOREIGN KEY (loc) REFERENCES iis.cmn_loc(id);
 B   ALTER TABLE ONLY iis.cmn_locatts DROP CONSTRAINT fk_cmn_locatts2;
       iis          iis    false    7401    751    749            J           2606    25356    cmn_locattx fk_cmn_locattx1    FK CONSTRAINT     y   ALTER TABLE ONLY iis.cmn_locattx
    ADD CONSTRAINT fk_cmn_locattx1 FOREIGN KEY (tableid) REFERENCES iis.cmn_locatt(id);
 B   ALTER TABLE ONLY iis.cmn_locattx DROP CONSTRAINT fk_cmn_locattx1;
       iis          iis    false    7404    750    752            K           2606    25361    cmn_loclink fk_cmn_loclink1    FK CONSTRAINT     s   ALTER TABLE ONLY iis.cmn_loclink
    ADD CONSTRAINT fk_cmn_loclink1 FOREIGN KEY (loc1) REFERENCES iis.cmn_loc(id);
 B   ALTER TABLE ONLY iis.cmn_loclink DROP CONSTRAINT fk_cmn_loclink1;
       iis          iis    false    7401    754    749            L           2606    25366    cmn_loclink fk_cmn_loclink2    FK CONSTRAINT     s   ALTER TABLE ONLY iis.cmn_loclink
    ADD CONSTRAINT fk_cmn_loclink2 FOREIGN KEY (loc2) REFERENCES iis.cmn_loc(id);
 B   ALTER TABLE ONLY iis.cmn_loclink DROP CONSTRAINT fk_cmn_loclink2;
       iis          iis    false    749    754    7401            M           2606    25371 !   cmn_loclinktpx fk_cmn_loclinktpx1    FK CONSTRAINT     �   ALTER TABLE ONLY iis.cmn_loclinktpx
    ADD CONSTRAINT fk_cmn_loclinktpx1 FOREIGN KEY (tableid) REFERENCES iis.cmn_loclinktp(id);
 H   ALTER TABLE ONLY iis.cmn_loclinktpx DROP CONSTRAINT fk_cmn_loclinktpx1;
       iis          iis    false    755    7413    756            N           2606    25376    cmn_loctpx fk_cmn_loctpx1    FK CONSTRAINT     v   ALTER TABLE ONLY iis.cmn_loctpx
    ADD CONSTRAINT fk_cmn_loctpx1 FOREIGN KEY (tableid) REFERENCES iis.cmn_loctp(id);
 @   ALTER TABLE ONLY iis.cmn_loctpx DROP CONSTRAINT fk_cmn_loctpx1;
       iis          iis    false    759    7420    760            O           2606    25381    cmn_locx fk_cmn_locx1    FK CONSTRAINT     p   ALTER TABLE ONLY iis.cmn_locx
    ADD CONSTRAINT fk_cmn_locx1 FOREIGN KEY (tableid) REFERENCES iis.cmn_loc(id);
 <   ALTER TABLE ONLY iis.cmn_locx DROP CONSTRAINT fk_cmn_locx1;
       iis          iis    false    762    7401    749            �           2606    25386    tmp_cmn_loc fk_cmn_lokacija2    FK CONSTRAINT     x   ALTER TABLE ONLY iis.tmp_cmn_loc
    ADD CONSTRAINT fk_cmn_lokacija2 FOREIGN KEY (tp) REFERENCES iis.tmp_cmn_loctp(id);
 C   ALTER TABLE ONLY iis.tmp_cmn_loc DROP CONSTRAINT fk_cmn_lokacija2;
       iis          iis    false    7713    944    943            Q           2606    25391    cmn_menux fk_cmn_menux1    FK CONSTRAINT     s   ALTER TABLE ONLY iis.cmn_menux
    ADD CONSTRAINT fk_cmn_menux1 FOREIGN KEY (tableid) REFERENCES iis.cmn_menu(id);
 >   ALTER TABLE ONLY iis.cmn_menux DROP CONSTRAINT fk_cmn_menux1;
       iis          iis    false    764    765    7427            R           2606    25396    cmn_modulex fk_cmn_modulex1    FK CONSTRAINT     y   ALTER TABLE ONLY iis.cmn_modulex
    ADD CONSTRAINT fk_cmn_modulex1 FOREIGN KEY (tableid) REFERENCES iis.cmn_module(id);
 B   ALTER TABLE ONLY iis.cmn_modulex DROP CONSTRAINT fk_cmn_modulex1;
       iis          iis    false    768    7432    767            5           2606    25401    cmn_obj fk_cmn_obj1    FK CONSTRAINT     l   ALTER TABLE ONLY iis.cmn_obj
    ADD CONSTRAINT fk_cmn_obj1 FOREIGN KEY (site) REFERENCES iis.cmn_site(id);
 :   ALTER TABLE ONLY iis.cmn_obj DROP CONSTRAINT fk_cmn_obj1;
       iis          iis    false    7490    731    802            S           2606    25406    cmn_objatt fk_cmn_objatt1    FK CONSTRAINT     ~   ALTER TABLE ONLY iis.cmn_objatt
    ADD CONSTRAINT fk_cmn_objatt1 FOREIGN KEY (cmn_objatttp) REFERENCES iis.cmn_objatttp(id);
 @   ALTER TABLE ONLY iis.cmn_objatt DROP CONSTRAINT fk_cmn_objatt1;
       iis          iis    false    7442    770    772            T           2606    25411    cmn_objatts fk_cmn_objatt2    FK CONSTRAINT     {   ALTER TABLE ONLY iis.cmn_objatts
    ADD CONSTRAINT fk_cmn_objatt2 FOREIGN KEY (cmn_objatt) REFERENCES iis.cmn_objatt(id);
 A   ALTER TABLE ONLY iis.cmn_objatts DROP CONSTRAINT fk_cmn_objatt2;
       iis          iis    false    770    7437    771            U           2606    25416    cmn_objatts fk_cmn_objatts1    FK CONSTRAINT     r   ALTER TABLE ONLY iis.cmn_objatts
    ADD CONSTRAINT fk_cmn_objatts1 FOREIGN KEY (obj) REFERENCES iis.cmn_obj(id);
 B   ALTER TABLE ONLY iis.cmn_objatts DROP CONSTRAINT fk_cmn_objatts1;
       iis          iis    false    731    7371    771            V           2606    25421    cmn_objatttpx fk_cmn_objatttpx1    FK CONSTRAINT        ALTER TABLE ONLY iis.cmn_objatttpx
    ADD CONSTRAINT fk_cmn_objatttpx1 FOREIGN KEY (tableid) REFERENCES iis.cmn_objatttp(id);
 F   ALTER TABLE ONLY iis.cmn_objatttpx DROP CONSTRAINT fk_cmn_objatttpx1;
       iis          iis    false    773    7442    772            W           2606    25426    cmn_objattx fk_cmn_objattx1    FK CONSTRAINT     y   ALTER TABLE ONLY iis.cmn_objattx
    ADD CONSTRAINT fk_cmn_objattx1 FOREIGN KEY (tableid) REFERENCES iis.cmn_objatt(id);
 B   ALTER TABLE ONLY iis.cmn_objattx DROP CONSTRAINT fk_cmn_objattx1;
       iis          iis    false    7437    775    770            6           2606    25431    cmn_obj fk_cmn_objekat2    FK CONSTRAINT     o   ALTER TABLE ONLY iis.cmn_obj
    ADD CONSTRAINT fk_cmn_objekat2 FOREIGN KEY (tp) REFERENCES iis.cmn_objtp(id);
 >   ALTER TABLE ONLY iis.cmn_obj DROP CONSTRAINT fk_cmn_objekat2;
       iis          iis    false    778    7451    731            ]           2606    25436    cmn_objtp fk_cmn_objekattip1    FK CONSTRAINT     u   ALTER TABLE ONLY iis.cmn_objtp
    ADD CONSTRAINT fk_cmn_objekattip1 FOREIGN KEY (site) REFERENCES iis.cmn_site(id);
 C   ALTER TABLE ONLY iis.cmn_objtp DROP CONSTRAINT fk_cmn_objekattip1;
       iis          iis    false    802    7490    778            7           2606    25441    cmn_objlink fk_cmn_objlink1    FK CONSTRAINT     x   ALTER TABLE ONLY iis.cmn_objlink
    ADD CONSTRAINT fk_cmn_objlink1 FOREIGN KEY (cmn_link) REFERENCES iis.cmn_link(id);
 B   ALTER TABLE ONLY iis.cmn_objlink DROP CONSTRAINT fk_cmn_objlink1;
       iis          iis    false    7396    746    732            8           2606    25446    cmn_objlink fk_cmn_objlink2    FK CONSTRAINT     s   ALTER TABLE ONLY iis.cmn_objlink
    ADD CONSTRAINT fk_cmn_objlink2 FOREIGN KEY (obj1) REFERENCES iis.cmn_obj(id);
 B   ALTER TABLE ONLY iis.cmn_objlink DROP CONSTRAINT fk_cmn_objlink2;
       iis          iis    false    731    732    7371            9           2606    25451    cmn_objlink fk_cmn_objlink3    FK CONSTRAINT     s   ALTER TABLE ONLY iis.cmn_objlink
    ADD CONSTRAINT fk_cmn_objlink3 FOREIGN KEY (obj2) REFERENCES iis.cmn_obj(id);
 B   ALTER TABLE ONLY iis.cmn_objlink DROP CONSTRAINT fk_cmn_objlink3;
       iis          iis    false    731    7371    732            :           2606    25456    cmn_objlink fk_cmn_objlink4    FK CONSTRAINT     w   ALTER TABLE ONLY iis.cmn_objlink
    ADD CONSTRAINT fk_cmn_objlink4 FOREIGN KEY (objtp1) REFERENCES iis.cmn_objtp(id);
 B   ALTER TABLE ONLY iis.cmn_objlink DROP CONSTRAINT fk_cmn_objlink4;
       iis          iis    false    778    7451    732            ;           2606    25461    cmn_objlink fk_cmn_objlink5    FK CONSTRAINT     w   ALTER TABLE ONLY iis.cmn_objlink
    ADD CONSTRAINT fk_cmn_objlink5 FOREIGN KEY (objtp2) REFERENCES iis.cmn_objtp(id);
 B   ALTER TABLE ONLY iis.cmn_objlink DROP CONSTRAINT fk_cmn_objlink5;
       iis          iis    false    7451    732    778            X           2606    25466 #   cmn_objlink_arr fk_cmn_objlink_arr1    FK CONSTRAINT     |   ALTER TABLE ONLY iis.cmn_objlink_arr
    ADD CONSTRAINT fk_cmn_objlink_arr1 FOREIGN KEY (site) REFERENCES iis.cmn_site(id);
 J   ALTER TABLE ONLY iis.cmn_objlink_arr DROP CONSTRAINT fk_cmn_objlink_arr1;
       iis          iis    false    7490    802    777            Y           2606    25471 #   cmn_objlink_arr fk_cmn_objlink_arr2    FK CONSTRAINT     {   ALTER TABLE ONLY iis.cmn_objlink_arr
    ADD CONSTRAINT fk_cmn_objlink_arr2 FOREIGN KEY (obj1) REFERENCES iis.cmn_obj(id);
 J   ALTER TABLE ONLY iis.cmn_objlink_arr DROP CONSTRAINT fk_cmn_objlink_arr2;
       iis          iis    false    7371    777    731            Z           2606    25476 #   cmn_objlink_arr fk_cmn_objlink_arr3    FK CONSTRAINT     {   ALTER TABLE ONLY iis.cmn_objlink_arr
    ADD CONSTRAINT fk_cmn_objlink_arr3 FOREIGN KEY (obj2) REFERENCES iis.cmn_obj(id);
 J   ALTER TABLE ONLY iis.cmn_objlink_arr DROP CONSTRAINT fk_cmn_objlink_arr3;
       iis          iis    false    731    777    7371            [           2606    25481 #   cmn_objlink_arr fk_cmn_objlink_arr4    FK CONSTRAINT        ALTER TABLE ONLY iis.cmn_objlink_arr
    ADD CONSTRAINT fk_cmn_objlink_arr4 FOREIGN KEY (objtp1) REFERENCES iis.cmn_objtp(id);
 J   ALTER TABLE ONLY iis.cmn_objlink_arr DROP CONSTRAINT fk_cmn_objlink_arr4;
       iis          iis    false    777    7451    778            \           2606    25486 #   cmn_objlink_arr fk_cmn_objlink_arr5    FK CONSTRAINT        ALTER TABLE ONLY iis.cmn_objlink_arr
    ADD CONSTRAINT fk_cmn_objlink_arr5 FOREIGN KEY (objtp2) REFERENCES iis.cmn_objtp(id);
 J   ALTER TABLE ONLY iis.cmn_objlink_arr DROP CONSTRAINT fk_cmn_objlink_arr5;
       iis          iis    false    778    7451    777            ^           2606    25491    cmn_objtpx fk_cmn_objtpx1    FK CONSTRAINT     v   ALTER TABLE ONLY iis.cmn_objtpx
    ADD CONSTRAINT fk_cmn_objtpx1 FOREIGN KEY (tableid) REFERENCES iis.cmn_objtp(id);
 @   ALTER TABLE ONLY iis.cmn_objtpx DROP CONSTRAINT fk_cmn_objtpx1;
       iis          iis    false    779    7451    778            _           2606    25496    cmn_objx fk_cmn_objx1    FK CONSTRAINT     p   ALTER TABLE ONLY iis.cmn_objx
    ADD CONSTRAINT fk_cmn_objx1 FOREIGN KEY (tableid) REFERENCES iis.cmn_obj(id);
 <   ALTER TABLE ONLY iis.cmn_objx DROP CONSTRAINT fk_cmn_objx1;
       iis          iis    false    781    731    7371            b           2606    25501    cmn_paratts fk_cmn_paratts1    FK CONSTRAINT     u   ALTER TABLE ONLY iis.cmn_paratts
    ADD CONSTRAINT fk_cmn_paratts1 FOREIGN KEY (att) REFERENCES iis.cmn_paratt(id);
 B   ALTER TABLE ONLY iis.cmn_paratts DROP CONSTRAINT fk_cmn_paratts1;
       iis          iis    false    786    785    7463            d           2606    25506    cmn_parattx fk_cmn_parattx1    FK CONSTRAINT     y   ALTER TABLE ONLY iis.cmn_parattx
    ADD CONSTRAINT fk_cmn_parattx1 FOREIGN KEY (tableid) REFERENCES iis.cmn_paratt(id);
 B   ALTER TABLE ONLY iis.cmn_parattx DROP CONSTRAINT fk_cmn_parattx1;
       iis          iis    false    787    785    7463            g           2606    25511 &   cmn_parcontacttpx fk_cmn_parcontacttp1    FK CONSTRAINT     �   ALTER TABLE ONLY iis.cmn_parcontacttpx
    ADD CONSTRAINT fk_cmn_parcontacttp1 FOREIGN KEY (tableid) REFERENCES iis.cmn_parcontacttp(id);
 M   ALTER TABLE ONLY iis.cmn_parcontacttpx DROP CONSTRAINT fk_cmn_parcontacttp1;
       iis          iis    false    7472    790    791            h           2606    25516    cmn_parlink fk_cmn_parlink1    FK CONSTRAINT     s   ALTER TABLE ONLY iis.cmn_parlink
    ADD CONSTRAINT fk_cmn_parlink1 FOREIGN KEY (par1) REFERENCES iis.cmn_par(id);
 B   ALTER TABLE ONLY iis.cmn_parlink DROP CONSTRAINT fk_cmn_parlink1;
       iis          iis    false    7458    793    783            i           2606    25521    cmn_parlink fk_cmn_parlink2    FK CONSTRAINT     s   ALTER TABLE ONLY iis.cmn_parlink
    ADD CONSTRAINT fk_cmn_parlink2 FOREIGN KEY (par2) REFERENCES iis.cmn_par(id);
 B   ALTER TABLE ONLY iis.cmn_parlink DROP CONSTRAINT fk_cmn_parlink2;
       iis          iis    false    783    7458    793            `           2606    25526    cmn_par fk_cmn_partner1    FK CONSTRAINT     o   ALTER TABLE ONLY iis.cmn_par
    ADD CONSTRAINT fk_cmn_partner1 FOREIGN KEY (tp) REFERENCES iis.cmn_partp(id);
 >   ALTER TABLE ONLY iis.cmn_par DROP CONSTRAINT fk_cmn_partner1;
       iis          iis    false    783    794    7479            e           2606    25531 %   cmn_parcontact fk_cmn_partnerkontakt1    FK CONSTRAINT     �   ALTER TABLE ONLY iis.cmn_parcontact
    ADD CONSTRAINT fk_cmn_partnerkontakt1 FOREIGN KEY (tp) REFERENCES iis.cmn_parcontacttp(id);
 L   ALTER TABLE ONLY iis.cmn_parcontact DROP CONSTRAINT fk_cmn_partnerkontakt1;
       iis          iis    false    790    7472    789            f           2606    25536 %   cmn_parcontact fk_cmn_partnerkontakt2    FK CONSTRAINT     �   ALTER TABLE ONLY iis.cmn_parcontact
    ADD CONSTRAINT fk_cmn_partnerkontakt2 FOREIGN KEY (cmn_par) REFERENCES iis.cmn_par(id);
 L   ALTER TABLE ONLY iis.cmn_parcontact DROP CONSTRAINT fk_cmn_partnerkontakt2;
       iis          iis    false    7458    789    783            c           2606    25541 $   cmn_paratts fk_cmn_partnerparametri2    FK CONSTRAINT     {   ALTER TABLE ONLY iis.cmn_paratts
    ADD CONSTRAINT fk_cmn_partnerparametri2 FOREIGN KEY (par) REFERENCES iis.cmn_par(id);
 K   ALTER TABLE ONLY iis.cmn_paratts DROP CONSTRAINT fk_cmn_partnerparametri2;
       iis          iis    false    786    783    7458            a           2606    25546 $   cmn_paraccount fk_cmn_partnertekuci1    FK CONSTRAINT        ALTER TABLE ONLY iis.cmn_paraccount
    ADD CONSTRAINT fk_cmn_partnertekuci1 FOREIGN KEY (cmn_par) REFERENCES iis.cmn_par(id);
 K   ALTER TABLE ONLY iis.cmn_paraccount DROP CONSTRAINT fk_cmn_partnertekuci1;
       iis          iis    false    7458    784    783            j           2606    25551    cmn_partpx fk_cmn_partpx1    FK CONSTRAINT     v   ALTER TABLE ONLY iis.cmn_partpx
    ADD CONSTRAINT fk_cmn_partpx1 FOREIGN KEY (tableid) REFERENCES iis.cmn_partp(id);
 @   ALTER TABLE ONLY iis.cmn_partpx DROP CONSTRAINT fk_cmn_partpx1;
       iis          iis    false    795    7479    794            k           2606    25556    cmn_parx fk_cmn_parx1    FK CONSTRAINT     p   ALTER TABLE ONLY iis.cmn_parx
    ADD CONSTRAINT fk_cmn_parx1 FOREIGN KEY (tableid) REFERENCES iis.cmn_par(id);
 <   ALTER TABLE ONLY iis.cmn_parx DROP CONSTRAINT fk_cmn_parx1;
       iis          iis    false    7458    797    783            l           2606    25561 !   cmn_paymenttpx fk_cmn_paymenttpx1    FK CONSTRAINT     �   ALTER TABLE ONLY iis.cmn_paymenttpx
    ADD CONSTRAINT fk_cmn_paymenttpx1 FOREIGN KEY (tableid) REFERENCES iis.cmn_paymenttp(id);
 H   ALTER TABLE ONLY iis.cmn_paymenttpx DROP CONSTRAINT fk_cmn_paymenttpx1;
       iis          iis    false    800    7485    799            �           2606    25566    tic_seat fk_cmn_seat1    FK CONSTRAINT     n   ALTER TABLE ONLY iis.tic_seat
    ADD CONSTRAINT fk_cmn_seat1 FOREIGN KEY (tp) REFERENCES iis.tic_seattp(id);
 <   ALTER TABLE ONLY iis.tic_seat DROP CONSTRAINT fk_cmn_seat1;
       iis          iis    false    927    7693    929            �           2606    25571    tic_seatloc fk_cmn_seatloc2    FK CONSTRAINT     t   ALTER TABLE ONLY iis.tic_seatloc
    ADD CONSTRAINT fk_cmn_seatloc2 FOREIGN KEY (seat) REFERENCES iis.tic_seat(id);
 B   ALTER TABLE ONLY iis.tic_seatloc DROP CONSTRAINT fk_cmn_seatloc2;
       iis          iis    false    928    927    7689            �           2606    25576 !   tic_seattpatts fk_cmn_seattpatts1    FK CONSTRAINT     ~   ALTER TABLE ONLY iis.tic_seattpatts
    ADD CONSTRAINT fk_cmn_seattpatts1 FOREIGN KEY (seattp) REFERENCES iis.tic_seattp(id);
 H   ALTER TABLE ONLY iis.tic_seattpatts DROP CONSTRAINT fk_cmn_seattpatts1;
       iis          iis    false    931    929    7693            �           2606    25581 !   tic_seattpatts fk_cmn_seattpatts2    FK CONSTRAINT     ~   ALTER TABLE ONLY iis.tic_seattpatts
    ADD CONSTRAINT fk_cmn_seattpatts2 FOREIGN KEY (att) REFERENCES iis.tic_seattpatt(id);
 H   ALTER TABLE ONLY iis.tic_seattpatts DROP CONSTRAINT fk_cmn_seattpatts2;
       iis          iis    false    930    7695    931            m           2606    25586    cmn_tax fk_cmn_tax1    FK CONSTRAINT     o   ALTER TABLE ONLY iis.cmn_tax
    ADD CONSTRAINT fk_cmn_tax1 FOREIGN KEY (country) REFERENCES iis.cmn_terr(id);
 :   ALTER TABLE ONLY iis.cmn_tax DROP CONSTRAINT fk_cmn_tax1;
       iis          iis    false    7500    807    803            n           2606    25591    cmn_taxrate fk_cmn_taxrate1    FK CONSTRAINT     r   ALTER TABLE ONLY iis.cmn_taxrate
    ADD CONSTRAINT fk_cmn_taxrate1 FOREIGN KEY (tax) REFERENCES iis.cmn_tax(id);
 B   ALTER TABLE ONLY iis.cmn_taxrate DROP CONSTRAINT fk_cmn_taxrate1;
       iis          iis    false    803    804    7493            o           2606    25596    cmn_taxx fk_cmn_taxx1    FK CONSTRAINT     p   ALTER TABLE ONLY iis.cmn_taxx
    ADD CONSTRAINT fk_cmn_taxx1 FOREIGN KEY (tableid) REFERENCES iis.cmn_tax(id);
 <   ALTER TABLE ONLY iis.cmn_taxx DROP CONSTRAINT fk_cmn_taxx1;
       iis          iis    false    805    7493    803            q           2606    25601    cmn_terratts fk_cmn_teratts1    FK CONSTRAINT     t   ALTER TABLE ONLY iis.cmn_terratts
    ADD CONSTRAINT fk_cmn_teratts1 FOREIGN KEY (loc) REFERENCES iis.cmn_terr(id);
 C   ALTER TABLE ONLY iis.cmn_terratts DROP CONSTRAINT fk_cmn_teratts1;
       iis          iis    false    809    807    7500            p           2606    25606    cmn_terr fk_cmn_terr1    FK CONSTRAINT     n   ALTER TABLE ONLY iis.cmn_terr
    ADD CONSTRAINT fk_cmn_terr1 FOREIGN KEY (tp) REFERENCES iis.cmn_terrtp(id);
 <   ALTER TABLE ONLY iis.cmn_terr DROP CONSTRAINT fk_cmn_terr1;
       iis          iis    false    7519    817    807            r           2606    25611    cmn_terratts fk_cmn_terratts2    FK CONSTRAINT     x   ALTER TABLE ONLY iis.cmn_terratts
    ADD CONSTRAINT fk_cmn_terratts2 FOREIGN KEY (att) REFERENCES iis.cmn_terratt(id);
 D   ALTER TABLE ONLY iis.cmn_terratts DROP CONSTRAINT fk_cmn_terratts2;
       iis          iis    false    7503    808    809            s           2606    25616    cmn_terrattx fk_cmn_terrattx1    FK CONSTRAINT     |   ALTER TABLE ONLY iis.cmn_terrattx
    ADD CONSTRAINT fk_cmn_terrattx1 FOREIGN KEY (tableid) REFERENCES iis.cmn_terratt(id);
 D   ALTER TABLE ONLY iis.cmn_terrattx DROP CONSTRAINT fk_cmn_terrattx1;
       iis          iis    false    808    7503    810            t           2606    25621    cmn_terrlink fk_cmn_terrlink1    FK CONSTRAINT     w   ALTER TABLE ONLY iis.cmn_terrlink
    ADD CONSTRAINT fk_cmn_terrlink1 FOREIGN KEY (terr1) REFERENCES iis.cmn_terr(id);
 D   ALTER TABLE ONLY iis.cmn_terrlink DROP CONSTRAINT fk_cmn_terrlink1;
       iis          iis    false    812    7500    807            u           2606    25626    cmn_terrlink fk_cmn_terrlink2    FK CONSTRAINT     w   ALTER TABLE ONLY iis.cmn_terrlink
    ADD CONSTRAINT fk_cmn_terrlink2 FOREIGN KEY (terr2) REFERENCES iis.cmn_terr(id);
 D   ALTER TABLE ONLY iis.cmn_terrlink DROP CONSTRAINT fk_cmn_terrlink2;
       iis          iis    false    7500    807    812            v           2606    25631    cmn_terrloc fk_cmn_terrloc1    FK CONSTRAINT     t   ALTER TABLE ONLY iis.cmn_terrloc
    ADD CONSTRAINT fk_cmn_terrloc1 FOREIGN KEY (terr) REFERENCES iis.cmn_terr(id);
 B   ALTER TABLE ONLY iis.cmn_terrloc DROP CONSTRAINT fk_cmn_terrloc1;
       iis          iis    false    816    807    7500            w           2606    25636    cmn_terrloc fk_cmn_terrloc2    FK CONSTRAINT     r   ALTER TABLE ONLY iis.cmn_terrloc
    ADD CONSTRAINT fk_cmn_terrloc2 FOREIGN KEY (loc) REFERENCES iis.cmn_loc(id);
 B   ALTER TABLE ONLY iis.cmn_terrloc DROP CONSTRAINT fk_cmn_terrloc2;
       iis          iis    false    749    816    7401            x           2606    25641    cmn_terrtpx fk_cmn_terrtpx1    FK CONSTRAINT     y   ALTER TABLE ONLY iis.cmn_terrtpx
    ADD CONSTRAINT fk_cmn_terrtpx1 FOREIGN KEY (tableid) REFERENCES iis.cmn_terrtp(id);
 B   ALTER TABLE ONLY iis.cmn_terrtpx DROP CONSTRAINT fk_cmn_terrtpx1;
       iis          iis    false    817    818    7519            y           2606    25646    cmn_terrx fk_cmn_terrx1    FK CONSTRAINT     s   ALTER TABLE ONLY iis.cmn_terrx
    ADD CONSTRAINT fk_cmn_terrx1 FOREIGN KEY (tableid) REFERENCES iis.cmn_terr(id);
 >   ALTER TABLE ONLY iis.cmn_terrx DROP CONSTRAINT fk_cmn_terrx1;
       iis          iis    false    7500    820    807            z           2606    25651    cmn_tgp fk_cmn_tgp1    FK CONSTRAINT     o   ALTER TABLE ONLY iis.cmn_tgp
    ADD CONSTRAINT fk_cmn_tgp1 FOREIGN KEY (country) REFERENCES iis.cmn_terr(id);
 :   ALTER TABLE ONLY iis.cmn_tgp DROP CONSTRAINT fk_cmn_tgp1;
       iis          iis    false    7500    807    822            {           2606    25656    cmn_tgptax fk_cmn_tgptax1    FK CONSTRAINT     p   ALTER TABLE ONLY iis.cmn_tgptax
    ADD CONSTRAINT fk_cmn_tgptax1 FOREIGN KEY (tgp) REFERENCES iis.cmn_tgp(id);
 @   ALTER TABLE ONLY iis.cmn_tgptax DROP CONSTRAINT fk_cmn_tgptax1;
       iis          iis    false    823    822    7526            |           2606    25661    cmn_tgptax fk_cmn_tgptax2    FK CONSTRAINT     p   ALTER TABLE ONLY iis.cmn_tgptax
    ADD CONSTRAINT fk_cmn_tgptax2 FOREIGN KEY (tax) REFERENCES iis.cmn_tax(id);
 @   ALTER TABLE ONLY iis.cmn_tgptax DROP CONSTRAINT fk_cmn_tgptax2;
       iis          iis    false    823    803    7493            }           2606    25666    cmn_tgpx fk_cmn_tgpx1    FK CONSTRAINT     p   ALTER TABLE ONLY iis.cmn_tgpx
    ADD CONSTRAINT fk_cmn_tgpx1 FOREIGN KEY (tableid) REFERENCES iis.cmn_tgp(id);
 <   ALTER TABLE ONLY iis.cmn_tgpx DROP CONSTRAINT fk_cmn_tgpx1;
       iis          iis    false    7526    822    824            �           2606    25671    cmn_umx fk_cmn_umx1    FK CONSTRAINT     m   ALTER TABLE ONLY iis.cmn_umx
    ADD CONSTRAINT fk_cmn_umx1 FOREIGN KEY (tableid) REFERENCES iis.cmn_um(id);
 :   ALTER TABLE ONLY iis.cmn_umx DROP CONSTRAINT fk_cmn_umx1;
       iis          iis    false    826    7533    828            E           2606    25676    cmn_link fk_cmn_vezatip1    FK CONSTRAINT     q   ALTER TABLE ONLY iis.cmn_link
    ADD CONSTRAINT fk_cmn_vezatip1 FOREIGN KEY (site) REFERENCES iis.cmn_site(id);
 ?   ALTER TABLE ONLY iis.cmn_link DROP CONSTRAINT fk_cmn_vezatip1;
       iis          iis    false    802    746    7490            P           2606    25681    cmn_menu fk_menu1    FK CONSTRAINT     n   ALTER TABLE ONLY iis.cmn_menu
    ADD CONSTRAINT fk_menu1 FOREIGN KEY (parentid) REFERENCES iis.cmn_menu(id);
 8   ALTER TABLE ONLY iis.cmn_menu DROP CONSTRAINT fk_menu1;
       iis          iis    false    7427    764    764            *           2606    25686    adm_rollstr fk_rolestr1    FK CONSTRAINT     p   ALTER TABLE ONLY iis.adm_rollstr
    ADD CONSTRAINT fk_rolestr1 FOREIGN KEY (roll) REFERENCES iis.adm_roll(id);
 >   ALTER TABLE ONLY iis.adm_rollstr DROP CONSTRAINT fk_rolestr1;
       iis          iis    false    711    7335    714            &           2606    25691    adm_rollact fk_rollact1    FK CONSTRAINT     p   ALTER TABLE ONLY iis.adm_rollact
    ADD CONSTRAINT fk_rollact1 FOREIGN KEY (roll) REFERENCES iis.adm_roll(id);
 >   ALTER TABLE ONLY iis.adm_rollact DROP CONSTRAINT fk_rollact1;
       iis          iis    false    7335    711    712            '           2606    25696    adm_rollact fk_rollact2    FK CONSTRAINT     t   ALTER TABLE ONLY iis.adm_rollact
    ADD CONSTRAINT fk_rollact2 FOREIGN KEY (action) REFERENCES iis.adm_action(id);
 >   ALTER TABLE ONLY iis.adm_rollact DROP CONSTRAINT fk_rollact2;
       iis          iis    false    702    712    7320            (           2606    25701    adm_rolllink fk_rolllink1    FK CONSTRAINT     s   ALTER TABLE ONLY iis.adm_rolllink
    ADD CONSTRAINT fk_rolllink1 FOREIGN KEY (roll1) REFERENCES iis.adm_roll(id);
 @   ALTER TABLE ONLY iis.adm_rolllink DROP CONSTRAINT fk_rolllink1;
       iis          iis    false    711    713    7335            )           2606    25706    adm_rolllink fk_rolllink2    FK CONSTRAINT     s   ALTER TABLE ONLY iis.adm_rolllink
    ADD CONSTRAINT fk_rolllink2 FOREIGN KEY (roll2) REFERENCES iis.adm_roll(id);
 @   ALTER TABLE ONLY iis.adm_rolllink DROP CONSTRAINT fk_rolllink2;
       iis          iis    false    713    7335    711            �           2606    25711    tic_doclink fk_tc_doclink1    FK CONSTRAINT     r   ALTER TABLE ONLY iis.tic_doclink
    ADD CONSTRAINT fk_tc_doclink1 FOREIGN KEY (doc1) REFERENCES iis.tic_doc(id);
 A   ALTER TABLE ONLY iis.tic_doclink DROP CONSTRAINT fk_tc_doclink1;
       iis          iis    false    872    876    7599            �           2606    25716    tic_doclink fk_tc_doclink2    FK CONSTRAINT     r   ALTER TABLE ONLY iis.tic_doclink
    ADD CONSTRAINT fk_tc_doclink2 FOREIGN KEY (doc2) REFERENCES iis.tic_doc(id);
 A   ALTER TABLE ONLY iis.tic_doclink DROP CONSTRAINT fk_tc_doclink2;
       iis          iis    false    7599    872    876            �           2606    25721    tic_docslink fk_tc_docslink2    FK CONSTRAINT     v   ALTER TABLE ONLY iis.tic_docslink
    ADD CONSTRAINT fk_tc_docslink2 FOREIGN KEY (docs1) REFERENCES iis.tic_docs(id);
 C   ALTER TABLE ONLY iis.tic_docslink DROP CONSTRAINT fk_tc_docslink2;
       iis          iis    false    879    7611    878            �           2606    25726    tic_docslink fk_tc_docslink3    FK CONSTRAINT     v   ALTER TABLE ONLY iis.tic_docslink
    ADD CONSTRAINT fk_tc_docslink3 FOREIGN KEY (docs2) REFERENCES iis.tic_docs(id);
 C   ALTER TABLE ONLY iis.tic_docslink DROP CONSTRAINT fk_tc_docslink3;
       iis          iis    false    879    878    7611            �           2606    25731    tic_agenda fk_tic_agenda1    FK CONSTRAINT     t   ALTER TABLE ONLY iis.tic_agenda
    ADD CONSTRAINT fk_tic_agenda1 FOREIGN KEY (tg) REFERENCES iis.tic_agendatp(id);
 @   ALTER TABLE ONLY iis.tic_agenda DROP CONSTRAINT fk_tic_agenda1;
       iis          iis    false    833    834    7543            �           2606    25736    tic_agendatpx fk_tic_agendatpx1    FK CONSTRAINT        ALTER TABLE ONLY iis.tic_agendatpx
    ADD CONSTRAINT fk_tic_agendatpx1 FOREIGN KEY (tableid) REFERENCES iis.tic_agendatp(id);
 F   ALTER TABLE ONLY iis.tic_agendatpx DROP CONSTRAINT fk_tic_agendatpx1;
       iis          iis    false    834    7543    835            �           2606    25741    tic_agendax fk_tic_agendax1    FK CONSTRAINT     y   ALTER TABLE ONLY iis.tic_agendax
    ADD CONSTRAINT fk_tic_agendax1 FOREIGN KEY (tableid) REFERENCES iis.tic_agenda(id);
 B   ALTER TABLE ONLY iis.tic_agendax DROP CONSTRAINT fk_tic_agendax1;
       iis          iis    false    7541    833    837            �           2606    25746    tic_art fk_tic_art1    FK CONSTRAINT     k   ALTER TABLE ONLY iis.tic_art
    ADD CONSTRAINT fk_tic_art1 FOREIGN KEY (tp) REFERENCES iis.tic_arttp(id);
 :   ALTER TABLE ONLY iis.tic_art DROP CONSTRAINT fk_tic_art1;
       iis          iis    false    7565    848    839            �           2606    25751    tic_art fk_tic_art2    FK CONSTRAINT     m   ALTER TABLE ONLY iis.tic_art
    ADD CONSTRAINT fk_tic_art2 FOREIGN KEY (grp) REFERENCES iis.tic_artgrp(id);
 :   ALTER TABLE ONLY iis.tic_art DROP CONSTRAINT fk_tic_art2;
       iis          iis    false    841    7553    839            �           2606    25756    tic_artcena fk_tic_artcena1    FK CONSTRAINT     r   ALTER TABLE ONLY iis.tic_artcena
    ADD CONSTRAINT fk_tic_artcena1 FOREIGN KEY (art) REFERENCES iis.tic_art(id);
 B   ALTER TABLE ONLY iis.tic_artcena DROP CONSTRAINT fk_tic_artcena1;
       iis          iis    false    839    840    7549            �           2606    25761    tic_artcena fk_tic_artcena2    FK CONSTRAINT     t   ALTER TABLE ONLY iis.tic_artcena
    ADD CONSTRAINT fk_tic_artcena2 FOREIGN KEY (cena) REFERENCES iis.tic_cena(id);
 B   ALTER TABLE ONLY iis.tic_artcena DROP CONSTRAINT fk_tic_artcena2;
       iis          iis    false    853    840    7571            �           2606    25766    tic_artgrpx fk_tic_artgrpx1    FK CONSTRAINT     y   ALTER TABLE ONLY iis.tic_artgrpx
    ADD CONSTRAINT fk_tic_artgrpx1 FOREIGN KEY (tableid) REFERENCES iis.tic_artgrp(id);
 B   ALTER TABLE ONLY iis.tic_artgrpx DROP CONSTRAINT fk_tic_artgrpx1;
       iis          iis    false    7553    842    841            �           2606    25771    tic_artlink fk_tic_artlink1    FK CONSTRAINT     s   ALTER TABLE ONLY iis.tic_artlink
    ADD CONSTRAINT fk_tic_artlink1 FOREIGN KEY (art1) REFERENCES iis.tic_art(id);
 B   ALTER TABLE ONLY iis.tic_artlink DROP CONSTRAINT fk_tic_artlink1;
       iis          iis    false    844    839    7549            �           2606    25776    tic_artlink fk_tic_artlink2    FK CONSTRAINT     s   ALTER TABLE ONLY iis.tic_artlink
    ADD CONSTRAINT fk_tic_artlink2 FOREIGN KEY (art2) REFERENCES iis.tic_art(id);
 B   ALTER TABLE ONLY iis.tic_artlink DROP CONSTRAINT fk_tic_artlink2;
       iis          iis    false    844    7549    839            �           2606    25781 %   tic_artprivilege fk_tic_artprivilege1    FK CONSTRAINT     |   ALTER TABLE ONLY iis.tic_artprivilege
    ADD CONSTRAINT fk_tic_artprivilege1 FOREIGN KEY (art) REFERENCES iis.tic_art(id);
 L   ALTER TABLE ONLY iis.tic_artprivilege DROP CONSTRAINT fk_tic_artprivilege1;
       iis          iis    false    7549    846    839            �           2606    25786 %   tic_artprivilege fk_tic_artprivilege2    FK CONSTRAINT     �   ALTER TABLE ONLY iis.tic_artprivilege
    ADD CONSTRAINT fk_tic_artprivilege2 FOREIGN KEY (privilege) REFERENCES iis.tic_privilege(id);
 L   ALTER TABLE ONLY iis.tic_artprivilege DROP CONSTRAINT fk_tic_artprivilege2;
       iis          iis    false    915    846    7671            �           2606    25791    tic_artloc fk_tic_artseat1    FK CONSTRAINT     q   ALTER TABLE ONLY iis.tic_artloc
    ADD CONSTRAINT fk_tic_artseat1 FOREIGN KEY (art) REFERENCES iis.tic_art(id);
 A   ALTER TABLE ONLY iis.tic_artloc DROP CONSTRAINT fk_tic_artseat1;
       iis          iis    false    7549    845    839            �           2606    25796    tic_arttax fk_tic_arttax1    FK CONSTRAINT     p   ALTER TABLE ONLY iis.tic_arttax
    ADD CONSTRAINT fk_tic_arttax1 FOREIGN KEY (art) REFERENCES iis.tic_art(id);
 @   ALTER TABLE ONLY iis.tic_arttax DROP CONSTRAINT fk_tic_arttax1;
       iis          iis    false    847    839    7549            �           2606    25801    tic_arttax fk_tic_arttax2    FK CONSTRAINT     p   ALTER TABLE ONLY iis.tic_arttax
    ADD CONSTRAINT fk_tic_arttax2 FOREIGN KEY (tax) REFERENCES iis.cmn_tax(id);
 @   ALTER TABLE ONLY iis.tic_arttax DROP CONSTRAINT fk_tic_arttax2;
       iis          iis    false    7493    847    803            �           2606    25806    tic_arttpx fk_tic_arttpx1    FK CONSTRAINT     v   ALTER TABLE ONLY iis.tic_arttpx
    ADD CONSTRAINT fk_tic_arttpx1 FOREIGN KEY (tableid) REFERENCES iis.tic_arttp(id);
 @   ALTER TABLE ONLY iis.tic_arttpx DROP CONSTRAINT fk_tic_arttpx1;
       iis          iis    false    849    7565    848            �           2606    25811    tic_artx fk_tic_artx1    FK CONSTRAINT     p   ALTER TABLE ONLY iis.tic_artx
    ADD CONSTRAINT fk_tic_artx1 FOREIGN KEY (tableid) REFERENCES iis.tic_art(id);
 <   ALTER TABLE ONLY iis.tic_artx DROP CONSTRAINT fk_tic_artx1;
       iis          iis    false    7549    851    839            �           2606    25816    tic_cena fk_tic_cena1    FK CONSTRAINT     n   ALTER TABLE ONLY iis.tic_cena
    ADD CONSTRAINT fk_tic_cena1 FOREIGN KEY (tp) REFERENCES iis.tic_cenatp(id);
 <   ALTER TABLE ONLY iis.tic_cena DROP CONSTRAINT fk_tic_cena1;
       iis          iis    false    853    854    7573            �           2606    25821    tic_cenatpx fk_tic_cenatpx1    FK CONSTRAINT     y   ALTER TABLE ONLY iis.tic_cenatpx
    ADD CONSTRAINT fk_tic_cenatpx1 FOREIGN KEY (tableid) REFERENCES iis.tic_cenatp(id);
 B   ALTER TABLE ONLY iis.tic_cenatpx DROP CONSTRAINT fk_tic_cenatpx1;
       iis          iis    false    854    7573    855            �           2606    25826    tic_cenax fk_tic_cenax1    FK CONSTRAINT     s   ALTER TABLE ONLY iis.tic_cenax
    ADD CONSTRAINT fk_tic_cenax1 FOREIGN KEY (tableid) REFERENCES iis.tic_cena(id);
 >   ALTER TABLE ONLY iis.tic_cenax DROP CONSTRAINT fk_tic_cenax1;
       iis          iis    false    7571    853    857            �           2606    25831 )   tic_chanellseatloc fk_tic_chanellseatloc1    FK CONSTRAINT     �   ALTER TABLE ONLY iis.tic_chanellseatloc
    ADD CONSTRAINT fk_tic_chanellseatloc1 FOREIGN KEY (chanell) REFERENCES iis.tic_channel(id);
 P   ALTER TABLE ONLY iis.tic_chanellseatloc DROP CONSTRAINT fk_tic_chanellseatloc1;
       iis          iis    false    7581    860    859            �           2606    25836 )   tic_chanellseatloc fk_tic_chanellseatloc2    FK CONSTRAINT     �   ALTER TABLE ONLY iis.tic_chanellseatloc
    ADD CONSTRAINT fk_tic_chanellseatloc2 FOREIGN KEY (seatloc) REFERENCES iis.tic_seatloc(id);
 P   ALTER TABLE ONLY iis.tic_chanellseatloc DROP CONSTRAINT fk_tic_chanellseatloc2;
       iis          iis    false    928    7691    859            �           2606    25841 +   tic_channeleventpar fk_tic_channeleventpar1    FK CONSTRAINT     �   ALTER TABLE ONLY iis.tic_channeleventpar
    ADD CONSTRAINT fk_tic_channeleventpar1 FOREIGN KEY (channel) REFERENCES iis.tic_channel(id);
 R   ALTER TABLE ONLY iis.tic_channeleventpar DROP CONSTRAINT fk_tic_channeleventpar1;
       iis          iis    false    860    861    7581            �           2606    25846 +   tic_channeleventpar fk_tic_channeleventpar2    FK CONSTRAINT     �   ALTER TABLE ONLY iis.tic_channeleventpar
    ADD CONSTRAINT fk_tic_channeleventpar2 FOREIGN KEY (event) REFERENCES iis.tic_event(id);
 R   ALTER TABLE ONLY iis.tic_channeleventpar DROP CONSTRAINT fk_tic_channeleventpar2;
       iis          iis    false    861    885    7621            �           2606    25851 +   tic_channeleventpar fk_tic_channeleventpar3    FK CONSTRAINT     �   ALTER TABLE ONLY iis.tic_channeleventpar
    ADD CONSTRAINT fk_tic_channeleventpar3 FOREIGN KEY (par) REFERENCES iis.cmn_par(id);
 R   ALTER TABLE ONLY iis.tic_channeleventpar DROP CONSTRAINT fk_tic_channeleventpar3;
       iis          iis    false    861    783    7458            �           2606    25856    tic_channelx fk_tic_channelx1    FK CONSTRAINT     |   ALTER TABLE ONLY iis.tic_channelx
    ADD CONSTRAINT fk_tic_channelx1 FOREIGN KEY (tableid) REFERENCES iis.tic_channel(id);
 D   ALTER TABLE ONLY iis.tic_channelx DROP CONSTRAINT fk_tic_channelx1;
       iis          iis    false    862    7581    860            �           2606    25861    tic_condtpx fk_tic_condtpx1    FK CONSTRAINT     y   ALTER TABLE ONLY iis.tic_condtpx
    ADD CONSTRAINT fk_tic_condtpx1 FOREIGN KEY (tableid) REFERENCES iis.tic_condtp(id);
 B   ALTER TABLE ONLY iis.tic_condtpx DROP CONSTRAINT fk_tic_condtpx1;
       iis          iis    false    7587    864    863            �           2606    25866    tic_discount fk_tic_discount1    FK CONSTRAINT     z   ALTER TABLE ONLY iis.tic_discount
    ADD CONSTRAINT fk_tic_discount1 FOREIGN KEY (tp) REFERENCES iis.tic_discounttp(id);
 D   ALTER TABLE ONLY iis.tic_discount DROP CONSTRAINT fk_tic_discount1;
       iis          iis    false    866    867    7593            �           2606    25871 #   tic_discounttpx fk_tic_discounttpx1    FK CONSTRAINT     �   ALTER TABLE ONLY iis.tic_discounttpx
    ADD CONSTRAINT fk_tic_discounttpx1 FOREIGN KEY (tableid) REFERENCES iis.tic_discounttp(id);
 J   ALTER TABLE ONLY iis.tic_discounttpx DROP CONSTRAINT fk_tic_discounttpx1;
       iis          iis    false    7593    868    867            �           2606    25876    tic_discountx fk_tic_discountx1    FK CONSTRAINT        ALTER TABLE ONLY iis.tic_discountx
    ADD CONSTRAINT fk_tic_discountx1 FOREIGN KEY (tableid) REFERENCES iis.tic_discount(id);
 F   ALTER TABLE ONLY iis.tic_discountx DROP CONSTRAINT fk_tic_discountx1;
       iis          iis    false    7591    870    866            �           2606    25881    tmp_tic_doc fk_tic_doc1    FK CONSTRAINT     r   ALTER TABLE ONLY iis.tmp_tic_doc
    ADD CONSTRAINT fk_tic_doc1 FOREIGN KEY (docvr) REFERENCES iis.tic_docvr(id);
 >   ALTER TABLE ONLY iis.tmp_tic_doc DROP CONSTRAINT fk_tic_doc1;
       iis          iis    false    882    945    7617            �           2606    25886    tic_doc fk_tic_doc1    FK CONSTRAINT     n   ALTER TABLE ONLY iis.tic_doc
    ADD CONSTRAINT fk_tic_doc1 FOREIGN KEY (docvr) REFERENCES iis.tic_docvr(id);
 :   ALTER TABLE ONLY iis.tic_doc DROP CONSTRAINT fk_tic_doc1;
       iis          iis    false    872    7617    882            �           2606    25891    tic_docb fk_tic_docb1    FK CONSTRAINT     l   ALTER TABLE ONLY iis.tic_docb
    ADD CONSTRAINT fk_tic_docb1 FOREIGN KEY (doc) REFERENCES iis.tic_doc(id);
 <   ALTER TABLE ONLY iis.tic_docb DROP CONSTRAINT fk_tic_docb1;
       iis          iis    false    872    873    7599            �           2606    25896 #   tic_docdelivery fk_tic_docdelivery1    FK CONSTRAINT     z   ALTER TABLE ONLY iis.tic_docdelivery
    ADD CONSTRAINT fk_tic_docdelivery1 FOREIGN KEY (doc) REFERENCES iis.tic_doc(id);
 J   ALTER TABLE ONLY iis.tic_docdelivery DROP CONSTRAINT fk_tic_docdelivery1;
       iis          postgres    false    7599    872    874            �           2606    25901 #   tic_docdocslink fk_tic_docdocslink1    FK CONSTRAINT     ~   ALTER TABLE ONLY iis.tic_docdocslink
    ADD CONSTRAINT fk_tic_docdocslink1 FOREIGN KEY (doc) REFERENCES iis.tic_doclink(id);
 J   ALTER TABLE ONLY iis.tic_docdocslink DROP CONSTRAINT fk_tic_docdocslink1;
       iis          iis    false    876    875    7607            �           2606    25906 #   tic_docdocslink fk_tic_docdocslink2    FK CONSTRAINT     �   ALTER TABLE ONLY iis.tic_docdocslink
    ADD CONSTRAINT fk_tic_docdocslink2 FOREIGN KEY (docs) REFERENCES iis.tic_docslink(id);
 J   ALTER TABLE ONLY iis.tic_docdocslink DROP CONSTRAINT fk_tic_docdocslink2;
       iis          iis    false    875    7613    879            �           2606    25911 !   tic_docpayment fk_tic_docpayment1    FK CONSTRAINT     x   ALTER TABLE ONLY iis.tic_docpayment
    ADD CONSTRAINT fk_tic_docpayment1 FOREIGN KEY (doc) REFERENCES iis.tic_doc(id);
 H   ALTER TABLE ONLY iis.tic_docpayment DROP CONSTRAINT fk_tic_docpayment1;
       iis          iis    false    877    7599    872            �           2606    25916    tic_docs fk_tic_docs1    FK CONSTRAINT     l   ALTER TABLE ONLY iis.tic_docs
    ADD CONSTRAINT fk_tic_docs1 FOREIGN KEY (doc) REFERENCES iis.tic_doc(id);
 <   ALTER TABLE ONLY iis.tic_docs DROP CONSTRAINT fk_tic_docs1;
       iis          iis    false    878    7599    872            �           2606    25921    tic_docs fk_tic_docs2    FK CONSTRAINT     l   ALTER TABLE ONLY iis.tic_docs
    ADD CONSTRAINT fk_tic_docs2 FOREIGN KEY (art) REFERENCES iis.tic_art(id);
 <   ALTER TABLE ONLY iis.tic_docs DROP CONSTRAINT fk_tic_docs2;
       iis          iis    false    878    7549    839            �           2606    25933    tic_docsuid fk_tic_docsuid1    FK CONSTRAINT     t   ALTER TABLE ONLY iis.tic_docsuid
    ADD CONSTRAINT fk_tic_docsuid1 FOREIGN KEY (docs) REFERENCES iis.tic_docs(id);
 B   ALTER TABLE ONLY iis.tic_docsuid DROP CONSTRAINT fk_tic_docsuid1;
       iis          postgres    false    880    878    7611            A           2606    25938    tic_doctpx fk_tic_doctpx1    FK CONSTRAINT     v   ALTER TABLE ONLY iis.tic_doctpx
    ADD CONSTRAINT fk_tic_doctpx1 FOREIGN KEY (tableid) REFERENCES iis.tic_doctp(id);
 @   ALTER TABLE ONLY iis.tic_doctpx DROP CONSTRAINT fk_tic_doctpx1;
       iis          iis    false    741    740    7387            �           2606    25943    tic_docvr fk_tic_docvr1    FK CONSTRAINT     o   ALTER TABLE ONLY iis.tic_docvr
    ADD CONSTRAINT fk_tic_docvr1 FOREIGN KEY (tp) REFERENCES iis.tic_doctp(id);
 >   ALTER TABLE ONLY iis.tic_docvr DROP CONSTRAINT fk_tic_docvr1;
       iis          iis    false    882    7387    740            �           2606    25948    tic_docvrx fk_tic_docvrx1    FK CONSTRAINT     v   ALTER TABLE ONLY iis.tic_docvrx
    ADD CONSTRAINT fk_tic_docvrx1 FOREIGN KEY (tableid) REFERENCES iis.tic_docvr(id);
 @   ALTER TABLE ONLY iis.tic_docvrx DROP CONSTRAINT fk_tic_docvrx1;
       iis          iis    false    7617    882    883            �           2606    25953    tic_event fk_tic_event1    FK CONSTRAINT     q   ALTER TABLE ONLY iis.tic_event
    ADD CONSTRAINT fk_tic_event1 FOREIGN KEY (tp) REFERENCES iis.tic_eventtp(id);
 >   ALTER TABLE ONLY iis.tic_event DROP CONSTRAINT fk_tic_event1;
       iis          iis    false    7659    907    885            �           2606    25958    tic_event fk_tic_event2    FK CONSTRAINT     s   ALTER TABLE ONLY iis.tic_event
    ADD CONSTRAINT fk_tic_event2 FOREIGN KEY (ctg) REFERENCES iis.tic_eventctg(id);
 >   ALTER TABLE ONLY iis.tic_event DROP CONSTRAINT fk_tic_event2;
       iis          iis    false    899    7645    885            �           2606    25963 #   tic_eventagenda fk_tic_eventagenda1    FK CONSTRAINT     ~   ALTER TABLE ONLY iis.tic_eventagenda
    ADD CONSTRAINT fk_tic_eventagenda1 FOREIGN KEY (event) REFERENCES iis.tic_event(id);
 J   ALTER TABLE ONLY iis.tic_eventagenda DROP CONSTRAINT fk_tic_eventagenda1;
       iis          iis    false    886    885    7621            �           2606    25968 #   tic_eventagenda fk_tic_eventagenda2    FK CONSTRAINT     �   ALTER TABLE ONLY iis.tic_eventagenda
    ADD CONSTRAINT fk_tic_eventagenda2 FOREIGN KEY (agenda) REFERENCES iis.tic_agenda(id);
 J   ALTER TABLE ONLY iis.tic_eventagenda DROP CONSTRAINT fk_tic_eventagenda2;
       iis          iis    false    886    7541    833            �           2606    25973    tic_eventart fk_tic_eventart1    FK CONSTRAINT     x   ALTER TABLE ONLY iis.tic_eventart
    ADD CONSTRAINT fk_tic_eventart1 FOREIGN KEY (event) REFERENCES iis.tic_event(id);
 D   ALTER TABLE ONLY iis.tic_eventart DROP CONSTRAINT fk_tic_eventart1;
       iis          iis    false    885    7621    887            �           2606    25978    tic_eventart fk_tic_eventart2    FK CONSTRAINT     t   ALTER TABLE ONLY iis.tic_eventart
    ADD CONSTRAINT fk_tic_eventart2 FOREIGN KEY (art) REFERENCES iis.tic_art(id);
 D   ALTER TABLE ONLY iis.tic_eventart DROP CONSTRAINT fk_tic_eventart2;
       iis          iis    false    887    839    7549            �           2606    25983 %   tic_eventartcena fk_tic_eventartcena1    FK CONSTRAINT     �   ALTER TABLE ONLY iis.tic_eventartcena
    ADD CONSTRAINT fk_tic_eventartcena1 FOREIGN KEY (eventart) REFERENCES iis.tic_eventart(id);
 L   ALTER TABLE ONLY iis.tic_eventartcena DROP CONSTRAINT fk_tic_eventartcena1;
       iis          iis    false    7625    887    888            �           2606    25988 %   tic_eventartcena fk_tic_eventartcena2    FK CONSTRAINT     ~   ALTER TABLE ONLY iis.tic_eventartcena
    ADD CONSTRAINT fk_tic_eventartcena2 FOREIGN KEY (cena) REFERENCES iis.tic_cena(id);
 L   ALTER TABLE ONLY iis.tic_eventartcena DROP CONSTRAINT fk_tic_eventartcena2;
       iis          iis    false    853    888    7571            �           2606    25993 %   tic_eventartlink fk_tic_eventartlink1    FK CONSTRAINT     �   ALTER TABLE ONLY iis.tic_eventartlink
    ADD CONSTRAINT fk_tic_eventartlink1 FOREIGN KEY (eventart1) REFERENCES iis.tic_eventart(id);
 L   ALTER TABLE ONLY iis.tic_eventartlink DROP CONSTRAINT fk_tic_eventartlink1;
       iis          iis    false    887    7625    889            �           2606    25998 %   tic_eventartlink fk_tic_eventartlink2    FK CONSTRAINT     �   ALTER TABLE ONLY iis.tic_eventartlink
    ADD CONSTRAINT fk_tic_eventartlink2 FOREIGN KEY (eventart2) REFERENCES iis.tic_eventart(id);
 L   ALTER TABLE ONLY iis.tic_eventartlink DROP CONSTRAINT fk_tic_eventartlink2;
       iis          iis    false    7625    887    889            �           2606    26003 #   tic_eventartloc fk_tic_eventartloc1    FK CONSTRAINT     �   ALTER TABLE ONLY iis.tic_eventartloc
    ADD CONSTRAINT fk_tic_eventartloc1 FOREIGN KEY (eventart) REFERENCES iis.tic_eventart(id);
 J   ALTER TABLE ONLY iis.tic_eventartloc DROP CONSTRAINT fk_tic_eventartloc1;
       iis          iis    false    890    887    7625            �           2606    26008    tic_eventatts fk_tic_eventatts1    FK CONSTRAINT     z   ALTER TABLE ONLY iis.tic_eventatts
    ADD CONSTRAINT fk_tic_eventatts1 FOREIGN KEY (event) REFERENCES iis.tic_event(id);
 F   ALTER TABLE ONLY iis.tic_eventatts DROP CONSTRAINT fk_tic_eventatts1;
       iis          iis    false    885    7621    892            �           2606    26013    tic_eventatts fk_tic_eventatts2    FK CONSTRAINT     {   ALTER TABLE ONLY iis.tic_eventatts
    ADD CONSTRAINT fk_tic_eventatts2 FOREIGN KEY (att) REFERENCES iis.tic_eventatt(id);
 F   ALTER TABLE ONLY iis.tic_eventatts DROP CONSTRAINT fk_tic_eventatts2;
       iis          iis    false    891    7633    892            �           2606    26018 #   tic_eventatttpx fk_tic_eventatttpx1    FK CONSTRAINT     �   ALTER TABLE ONLY iis.tic_eventatttpx
    ADD CONSTRAINT fk_tic_eventatttpx1 FOREIGN KEY (tableid) REFERENCES iis.tic_eventatttp(id);
 J   ALTER TABLE ONLY iis.tic_eventatttpx DROP CONSTRAINT fk_tic_eventatttpx1;
       iis          postgres    false    894    893    7637            �           2606    26023    tic_eventattx fk_tic_eventattx1    FK CONSTRAINT        ALTER TABLE ONLY iis.tic_eventattx
    ADD CONSTRAINT fk_tic_eventattx1 FOREIGN KEY (tableid) REFERENCES iis.tic_eventatt(id);
 F   ALTER TABLE ONLY iis.tic_eventattx DROP CONSTRAINT fk_tic_eventattx1;
       iis          iis    false    891    7633    896            �           2606    26028 #   tic_eventcenatp fk_tic_eventcenatp1    FK CONSTRAINT     ~   ALTER TABLE ONLY iis.tic_eventcenatp
    ADD CONSTRAINT fk_tic_eventcenatp1 FOREIGN KEY (event) REFERENCES iis.tic_event(id);
 J   ALTER TABLE ONLY iis.tic_eventcenatp DROP CONSTRAINT fk_tic_eventcenatp1;
       iis          iis    false    898    7621    885            �           2606    26033 #   tic_eventcenatp fk_tic_eventcenatp2    FK CONSTRAINT     �   ALTER TABLE ONLY iis.tic_eventcenatp
    ADD CONSTRAINT fk_tic_eventcenatp2 FOREIGN KEY (cenatp) REFERENCES iis.tic_cenatp(id);
 J   ALTER TABLE ONLY iis.tic_eventcenatp DROP CONSTRAINT fk_tic_eventcenatp2;
       iis          iis    false    854    7573    898            �           2606    26038    tic_eventctgx fk_tic_eventctgx1    FK CONSTRAINT        ALTER TABLE ONLY iis.tic_eventctgx
    ADD CONSTRAINT fk_tic_eventctgx1 FOREIGN KEY (tableid) REFERENCES iis.tic_eventctg(id);
 F   ALTER TABLE ONLY iis.tic_eventctgx DROP CONSTRAINT fk_tic_eventctgx1;
       iis          iis    false    899    900    7645            �           2606    26043    tic_eventlink fk_tic_eventlink1    FK CONSTRAINT     {   ALTER TABLE ONLY iis.tic_eventlink
    ADD CONSTRAINT fk_tic_eventlink1 FOREIGN KEY (event1) REFERENCES iis.tic_event(id);
 F   ALTER TABLE ONLY iis.tic_eventlink DROP CONSTRAINT fk_tic_eventlink1;
       iis          iis    false    885    902    7621            �           2606    26048    tic_eventlink fk_tic_eventlink2    FK CONSTRAINT     {   ALTER TABLE ONLY iis.tic_eventlink
    ADD CONSTRAINT fk_tic_eventlink2 FOREIGN KEY (event2) REFERENCES iis.tic_event(id);
 F   ALTER TABLE ONLY iis.tic_eventlink DROP CONSTRAINT fk_tic_eventlink2;
       iis          iis    false    902    885    7621            �           2606    26053    tic_eventloc fk_tic_eventloc1    FK CONSTRAINT     x   ALTER TABLE ONLY iis.tic_eventloc
    ADD CONSTRAINT fk_tic_eventloc1 FOREIGN KEY (event) REFERENCES iis.tic_event(id);
 D   ALTER TABLE ONLY iis.tic_eventloc DROP CONSTRAINT fk_tic_eventloc1;
       iis          iis    false    885    7621    903            �           2606    26058    tic_eventobj fk_tic_eventobj1    FK CONSTRAINT     x   ALTER TABLE ONLY iis.tic_eventobj
    ADD CONSTRAINT fk_tic_eventobj1 FOREIGN KEY (event) REFERENCES iis.tic_event(id);
 D   ALTER TABLE ONLY iis.tic_eventobj DROP CONSTRAINT fk_tic_eventobj1;
       iis          iis    false    904    885    7621            �           2606    26063    tic_events fk_tic_events1    FK CONSTRAINT     q   ALTER TABLE ONLY iis.tic_events
    ADD CONSTRAINT fk_tic_events1 FOREIGN KEY (id) REFERENCES iis.tic_event(id);
 @   ALTER TABLE ONLY iis.tic_events DROP CONSTRAINT fk_tic_events1;
       iis          iis    false    885    7621    905            �           2606    26068    tic_eventtps fk_tic_eventtps1    FK CONSTRAINT     |   ALTER TABLE ONLY iis.tic_eventtps
    ADD CONSTRAINT fk_tic_eventtps1 FOREIGN KEY (eventtp) REFERENCES iis.tic_eventtp(id);
 D   ALTER TABLE ONLY iis.tic_eventtps DROP CONSTRAINT fk_tic_eventtps1;
       iis          iis    false    7659    907    908            �           2606    26073    tic_eventtps fk_tic_eventtps2    FK CONSTRAINT     y   ALTER TABLE ONLY iis.tic_eventtps
    ADD CONSTRAINT fk_tic_eventtps2 FOREIGN KEY (att) REFERENCES iis.tic_eventatt(id);
 D   ALTER TABLE ONLY iis.tic_eventtps DROP CONSTRAINT fk_tic_eventtps2;
       iis          iis    false    891    7633    908            �           2606    26078    tic_eventtpx fk_tic_eventtpx1    FK CONSTRAINT     |   ALTER TABLE ONLY iis.tic_eventtpx
    ADD CONSTRAINT fk_tic_eventtpx1 FOREIGN KEY (tableid) REFERENCES iis.tic_eventtp(id);
 D   ALTER TABLE ONLY iis.tic_eventtpx DROP CONSTRAINT fk_tic_eventtpx1;
       iis          iis    false    909    7659    907            �           2606    26083    tic_eventx fk_tic_eventx1    FK CONSTRAINT     v   ALTER TABLE ONLY iis.tic_eventx
    ADD CONSTRAINT fk_tic_eventx1 FOREIGN KEY (tableid) REFERENCES iis.tic_event(id);
 @   ALTER TABLE ONLY iis.tic_eventx DROP CONSTRAINT fk_tic_eventx1;
       iis          iis    false    885    911    7621            �           2606    26088 %   tic_parprivilege fk_tic_parprivilege1    FK CONSTRAINT     �   ALTER TABLE ONLY iis.tic_parprivilege
    ADD CONSTRAINT fk_tic_parprivilege1 FOREIGN KEY (privilege) REFERENCES iis.tic_privilege(id);
 L   ALTER TABLE ONLY iis.tic_parprivilege DROP CONSTRAINT fk_tic_parprivilege1;
       iis          iis    false    915    7671    913            �           2606    26093    tic_paycard fk_tic_paycard1    FK CONSTRAINT     �   ALTER TABLE ONLY iis.tic_paycard
    ADD CONSTRAINT fk_tic_paycard1 FOREIGN KEY (docpayment) REFERENCES iis.tic_docpayment(id);
 B   ALTER TABLE ONLY iis.tic_paycard DROP CONSTRAINT fk_tic_paycard1;
       iis          iis    false    877    7609    914            �           2606    26098    tic_privilege fk_tic_privilege1    FK CONSTRAINT     }   ALTER TABLE ONLY iis.tic_privilege
    ADD CONSTRAINT fk_tic_privilege1 FOREIGN KEY (tp) REFERENCES iis.tic_privilegetp(id);
 F   ALTER TABLE ONLY iis.tic_privilege DROP CONSTRAINT fk_tic_privilege1;
       iis          iis    false    915    919    7679            �           2606    26103 '   tic_privilegecond fk_tic_privilegecond1    FK CONSTRAINT     �   ALTER TABLE ONLY iis.tic_privilegecond
    ADD CONSTRAINT fk_tic_privilegecond1 FOREIGN KEY (privilege) REFERENCES iis.tic_privilege(id);
 N   ALTER TABLE ONLY iis.tic_privilegecond DROP CONSTRAINT fk_tic_privilegecond1;
       iis          iis    false    915    7671    916            �           2606    26108 '   tic_privilegecond fk_tic_privilegecond2    FK CONSTRAINT     �   ALTER TABLE ONLY iis.tic_privilegecond
    ADD CONSTRAINT fk_tic_privilegecond2 FOREIGN KEY (begcondtp) REFERENCES iis.tic_condtp(id);
 N   ALTER TABLE ONLY iis.tic_privilegecond DROP CONSTRAINT fk_tic_privilegecond2;
       iis          iis    false    916    7587    863            �           2606    26113 '   tic_privilegecond fk_tic_privilegecond3    FK CONSTRAINT     �   ALTER TABLE ONLY iis.tic_privilegecond
    ADD CONSTRAINT fk_tic_privilegecond3 FOREIGN KEY (endcondtp) REFERENCES iis.tic_condtp(id);
 N   ALTER TABLE ONLY iis.tic_privilegecond DROP CONSTRAINT fk_tic_privilegecond3;
       iis          iis    false    916    863    7587            �           2606    26118 /   tic_privilegediscount fk_tic_privilegediscount1    FK CONSTRAINT     �   ALTER TABLE ONLY iis.tic_privilegediscount
    ADD CONSTRAINT fk_tic_privilegediscount1 FOREIGN KEY (privilege) REFERENCES iis.tic_privilege(id);
 V   ALTER TABLE ONLY iis.tic_privilegediscount DROP CONSTRAINT fk_tic_privilegediscount1;
       iis          iis    false    917    915    7671            �           2606    26123 /   tic_privilegediscount fk_tic_privilegediscount2    FK CONSTRAINT     �   ALTER TABLE ONLY iis.tic_privilegediscount
    ADD CONSTRAINT fk_tic_privilegediscount2 FOREIGN KEY (discount) REFERENCES iis.tic_discount(id);
 V   ALTER TABLE ONLY iis.tic_privilegediscount DROP CONSTRAINT fk_tic_privilegediscount2;
       iis          iis    false    866    7591    917            �           2606    26128 '   tic_privilegelink fk_tic_privilegelink1    FK CONSTRAINT     �   ALTER TABLE ONLY iis.tic_privilegelink
    ADD CONSTRAINT fk_tic_privilegelink1 FOREIGN KEY (privilege1) REFERENCES iis.tic_privilege(id);
 N   ALTER TABLE ONLY iis.tic_privilegelink DROP CONSTRAINT fk_tic_privilegelink1;
       iis          iis    false    7671    918    915            �           2606    26133 '   tic_privilegelink fk_tic_privilegelink2    FK CONSTRAINT     �   ALTER TABLE ONLY iis.tic_privilegelink
    ADD CONSTRAINT fk_tic_privilegelink2 FOREIGN KEY (privilege2) REFERENCES iis.tic_privilege(id);
 N   ALTER TABLE ONLY iis.tic_privilegelink DROP CONSTRAINT fk_tic_privilegelink2;
       iis          iis    false    7671    918    915            �           2606    26138 %   tic_privilegetpx fk_tic_privilegetpx1    FK CONSTRAINT     �   ALTER TABLE ONLY iis.tic_privilegetpx
    ADD CONSTRAINT fk_tic_privilegetpx1 FOREIGN KEY (tableid) REFERENCES iis.tic_privilegetp(id);
 L   ALTER TABLE ONLY iis.tic_privilegetpx DROP CONSTRAINT fk_tic_privilegetpx1;
       iis          iis    false    920    7679    919            �           2606    26143 !   tic_privilegex fk_tic_privilegex1    FK CONSTRAINT     �   ALTER TABLE ONLY iis.tic_privilegex
    ADD CONSTRAINT fk_tic_privilegex1 FOREIGN KEY (tableid) REFERENCES iis.tic_privilege(id);
 H   ALTER TABLE ONLY iis.tic_privilegex DROP CONSTRAINT fk_tic_privilegex1;
       iis          iis    false    915    922    7671            �           2606    26148    tic_event fk_tic_season1    FK CONSTRAINT     u   ALTER TABLE ONLY iis.tic_event
    ADD CONSTRAINT fk_tic_season1 FOREIGN KEY (season) REFERENCES iis.tic_season(id);
 ?   ALTER TABLE ONLY iis.tic_event DROP CONSTRAINT fk_tic_season1;
       iis          iis    false    924    885    7685            �           2606    26153    tic_seasonx fk_tic_seasonx1    FK CONSTRAINT     y   ALTER TABLE ONLY iis.tic_seasonx
    ADD CONSTRAINT fk_tic_seasonx1 FOREIGN KEY (tableid) REFERENCES iis.tic_season(id);
 B   ALTER TABLE ONLY iis.tic_seasonx DROP CONSTRAINT fk_tic_seasonx1;
       iis          iis    false    924    925    7685            �           2606    26158 !   tic_seattpattx fk_tic_seattpattx1    FK CONSTRAINT     �   ALTER TABLE ONLY iis.tic_seattpattx
    ADD CONSTRAINT fk_tic_seattpattx1 FOREIGN KEY (tableid) REFERENCES iis.tic_seattpatt(id);
 H   ALTER TABLE ONLY iis.tic_seattpattx DROP CONSTRAINT fk_tic_seattpattx1;
       iis          iis    false    7695    930    932            �           2606    26163    tic_seattpx fk_tic_seattpx1    FK CONSTRAINT     y   ALTER TABLE ONLY iis.tic_seattpx
    ADD CONSTRAINT fk_tic_seattpx1 FOREIGN KEY (tableid) REFERENCES iis.tic_seattp(id);
 B   ALTER TABLE ONLY iis.tic_seattpx DROP CONSTRAINT fk_tic_seattpx1;
       iis          iis    false    929    7693    933            �           2606    26168    tic_seatx fk_tic_seatx1    FK CONSTRAINT     s   ALTER TABLE ONLY iis.tic_seatx
    ADD CONSTRAINT fk_tic_seatx1 FOREIGN KEY (tableid) REFERENCES iis.tic_seat(id);
 >   ALTER TABLE ONLY iis.tic_seatx DROP CONSTRAINT fk_tic_seatx1;
       iis          iis    false    7689    934    927            �           2606    26173    tic_speccheck fk_tic_speccheck1    FK CONSTRAINT     �   ALTER TABLE ONLY iis.tic_speccheck
    ADD CONSTRAINT fk_tic_speccheck1 FOREIGN KEY (docpayment) REFERENCES iis.tic_docpayment(id);
 F   ALTER TABLE ONLY iis.tic_speccheck DROP CONSTRAINT fk_tic_speccheck1;
       iis          iis    false    7609    877    935            �           2606    26178    tic_stampa fk_tic_stampa1    FK CONSTRAINT     r   ALTER TABLE ONLY iis.tic_stampa
    ADD CONSTRAINT fk_tic_stampa1 FOREIGN KEY (docs) REFERENCES iis.tic_docs(id);
 @   ALTER TABLE ONLY iis.tic_stampa DROP CONSTRAINT fk_tic_stampa1;
       iis          iis    false    7611    936    878            ,           2606    26183    adm_user fk_user1    FK CONSTRAINT     p   ALTER TABLE ONLY iis.adm_user
    ADD CONSTRAINT fk_user1 FOREIGN KEY (usergrp) REFERENCES iis.adm_usergrp(id);
 8   ALTER TABLE ONLY iis.adm_user DROP CONSTRAINT fk_user1;
       iis          iis    false    718    7354    719            /           2606    26188    adm_userlink fk_userlink1    FK CONSTRAINT     s   ALTER TABLE ONLY iis.adm_userlink
    ADD CONSTRAINT fk_userlink1 FOREIGN KEY (user1) REFERENCES iis.adm_user(id);
 @   ALTER TABLE ONLY iis.adm_userlink DROP CONSTRAINT fk_userlink1;
       iis          iis    false    725    718    7351            0           2606    26193 '   adm_userlinkpremiss fk_userlinkpremiss1    FK CONSTRAINT     �   ALTER TABLE ONLY iis.adm_userlinkpremiss
    ADD CONSTRAINT fk_userlinkpremiss1 FOREIGN KEY (userlink) REFERENCES iis.adm_userlink(id);
 N   ALTER TABLE ONLY iis.adm_userlinkpremiss DROP CONSTRAINT fk_userlinkpremiss1;
       iis          iis    false    7360    726    725            1           2606    26198 '   adm_userlinkpremiss fk_userlinkpremiss2    FK CONSTRAINT     �   ALTER TABLE ONLY iis.adm_userlinkpremiss
    ADD CONSTRAINT fk_userlinkpremiss2 FOREIGN KEY (userpermiss) REFERENCES iis.adm_userpermiss(id);
 N   ALTER TABLE ONLY iis.adm_userlinkpremiss DROP CONSTRAINT fk_userlinkpremiss2;
       iis          iis    false    728    7368    726            3           2606    26203    adm_userpermiss fk_userrole1    FK CONSTRAINT     t   ALTER TABLE ONLY iis.adm_userpermiss
    ADD CONSTRAINT fk_userrole1 FOREIGN KEY (usr) REFERENCES iis.adm_user(id);
 C   ALTER TABLE ONLY iis.adm_userpermiss DROP CONSTRAINT fk_userrole1;
       iis          iis    false    7351    728    718            4           2606    26208    adm_userpermiss fk_userrole2    FK CONSTRAINT     u   ALTER TABLE ONLY iis.adm_userpermiss
    ADD CONSTRAINT fk_userrole2 FOREIGN KEY (roll) REFERENCES iis.adm_roll(id);
 C   ALTER TABLE ONLY iis.adm_userpermiss DROP CONSTRAINT fk_userrole2;
       iis          iis    false    711    728    7335                   x������ � �          �  x�mWˎ#7<�|L@��c���{�q�������n{����Z-���.6�$��D�I��K�L��ӗ߿��Ƿ�r�	0/T�}��Md��]����u���=P�6��s���4�ͷw��H�焩H^�5�tG��w9�Ț~���qY>�J�'K.�o��z:	�To���xcdɅ���	�3ʾ�}�y�ͻ�t���&�!�2�yZ���4`x���`=��tƂ�o���`-v��*؟/�p�~SH���D.�W��TD6θ�9j��~�P��8o�mtġy�AE_�"6�5]�P�p)����͓�EB�I�q��7O*R���;f�LP�S�%ٹBm��c�xB�/|h��z�v�OEDԈ��*h������q�L�}����%U��8Ȏ1l$E�O!��8��Q[`7��.��N����r���͏s{tZv�Dk�?�_�iW�RP�b��&o�H/�����LĄ�v�
�6ߏ��m�&Ҷ�rĲq�?�,%
gb��p\��ǥ�J�J�+����Y6"��ʅ��`쯗�6���c�I�ı��0�Ƿ2Hf�e�N?/�~�11a�<�-�jq��7"��沋�q-���l�$�� ���A�E�a0�+��\|,��%k�%%�s��솒�`c�$Q.���W7D���{R+�,�U�XY�B1h��â�݄^!�,�J��
*z �J�����w6a���"��UA�[�Z��}?]v
��!����h�_��'����?�̔�E�b����}VH�9��آ7bEnG}�9��͆�IL�QH��s�Ȓ`��*W�`��P����˓�D�����_��~7�䀚�سj9~��I-%J&���}� ��BQr���c��]�"DL��A�o%�D���̕�ei7D�P�)5a��v�!Ό:�*	��Spxѥ��{�8x�|;h��-�Fo;��"�Q#����X��q9L/�A�F��YZ�[K�Ԃ��?>{%r�V�9��И��0"A���d?k�r�\�{[o��ן_�gN�p[�`*���с��ű��k/��zx���?Wb.�8��|Wlgzm���PH�q;������ҹ�P���}wgw���h?��ks�Ri�AO��kx���@-�I��~��^����c��V��Zb��P����y����$J���{Z!&�Niؼ�������I�             x������ � �             x������ � �              x������ � �      !    �   x��O
�@��3���8:���mY`DAƜ�B
*.\���!,2��3��F��6���(��C]ƙǅ��1�D(��^5mQWh���(%��f��&���������3�]�x�*i�����[�ڮ&u���U)�`�'}�����/����J_Ȭ�|�M�e�.V�f��8�1�?9"D?      "       x������ � �      #    `   x�m���@C�l1�4�
�&��:i�>LT(���(��5&҅� ���h>5�q�bR�Ru!�c{=�?�a��$��l*�G��rx}�Z7~�`      $      x�M��N�0E��W��g�㱗-�H�����DQ�pP!�Ǳ�poι�;�k��Z��V��h�I؃C�V�9Šn7���^4 3��	A��BQ�&Z/�]�^�jbק1k�]}T��x.��R�?��d��C�{��R%R-/�
�X��U�Y��)@L@�6A�8V���,��a�e��8�$�`��d1c���e��6mS�Sț�
��]�NɃ�@`�%�A�$�����66�Wp��֩"���{�y;Ko�C~m��0���,�~ �j>      %    �   x����	�@�7��-/�	��u�Җ�p ۟�����f�������!�L�Ħc�K3e"��ܱF�ͷ?��t,�Ȣ�`�X
�}�4�&:E/ly;[�R��E���&�Whղ67�7�d�pBfD��f5�l�	1���:K^��^�:G�؇�O�~߶�	�\Z�      &    ?   x�%ȹ�@���X��&\��_�I��Za�K�g��y_[����o��c��	�<�z��V      '    �   x�}��AC�3�D����T�����Un�o�<(��dx�����n��RfJ-!K���J���LH�TI�F� 6o �4��#W�3e�_�u��0�$b���m��9��;a�����|&�(��S��~sL]���EQo*�N�uHׯ��J��5�������_7�?K      (    ,  x�e��j�0E��W��<43�2]v
�2PDb��
��u���ǑCv�s���V��>���w��ͱB�l1�Y�x�u�B(�k�mҮm�>���vm«�4 �@,�[,fZ<�S�4m�^s���ꋄ�%����6J&1�"yk����M;���rD���K�8���?��<�>�T0�ahF�Q��,���)`1&!��n��@�Jw e�"j��|.^2pK�I�?��\�oS���S׏AFo@�ަ����g��Z�e���B�u�c�i}��c�����7U�����/��      )       x������ � �      *    `  x�}�;s�6�k�S�pM�A@��-�z�,Y���|�")��DR'U�K�"M�����d�O�s���7
��minB�b����.T�wa���������=e_���w�Oۏ���S��������[�Kr��_P� 4�!E�� A���1%�C1�P^*���A�z�r��7�c�x<m�]K|۞�WN���mS�'�lל�b��� Ua�R���o�c�E�~����f�r�i�ˁ:g<ٮ{V��3o�	1ֵs�A�f2
(������8��e��&���b3 �ˤ�r�����!��j�7D-��ז<]Y�R�R��}�x�����������k�;0�0׈�a��~*���<��P�!�	�Hś�b����ɤց�aq��CzV������׭ng���7��t�M�U_��gN�<Ub�]�ع�.$�F�F A�B8 g�A�TǄ�ა��o�G!�C������ʵ��x0�Z��`}��tӞ3��w|��X�pe?��}�;1??3���2(���f��G~uȹ��	�����s�Qʡ� 	���-B�"Io�����b�\g����U�7Iҭ<J_�RgM�w���n��҆YW:�c/�W����EW7W�\8��&�J,���7 Ct�ޚ��9�)#��0(ɪ����G��Z����k���#�i����Wܪ��V�����+(k̚=�h��C�b)��s
/3�%9T9^9���3�xѡL��� ��3�|�.ee��Ǩ�Һ�'�YY8Būˠ$.��#�Vۍ�ÕU�������'�!�����%���Q�~����^�����v���;DcG�"���B������      ,       x������ � �      +    �   x�]�1�0���+��].�ɨе:tq�(A��DK�����oy|��(d�eg�.�,�9C;�G�<܁m��h�,VHtV>@�y�i��X�,�D��gP'�A��f��[����d��춭K9��ǯ���v����yX��뛣R���4�      -    �   x�U�=n1��{
Nͯ=S�RڤHA��V	B(aAfS$�g���}�<cE#c�HF�&a���*S����C�3�q���[B¬ٴ�G��T�r��"�#��$nd���ʏ��6/�<�5w�h��/�j��W�}qJ
����3{s�{����c�z��ܣ8xJd7���:���o��K�u�T�      .       x������ � �      /       x������ � �      0       x������ � �      1    f   x�=��A��N0.�K��#���0>�_�A��9�	�p�ϋB��[�����\Т���e��U��Wοx�r�6WV������"�x��j�?2S�s?�9/�_�      4    8   x�3����v��\F _��� N���T��1H���ϑ�%3/(���� ��      5       x������ � �      6    �   x�����0�k{
&@~���~K0A��DAK��,@R�Of8o��%*�;��#�X�XMS`K����	3�*e_���b'Jb9�iv\��X�Ʒ�I	�n���O�*p)ܱlpŊ.eh�U#E���`���ÛoĂ�_�~�~N6      7    e   x����	�P�~��~�5���:bY,���f]��n�[��
�jJ���v��hPzB�y1���p�Vm6�lƁ����[e>�̊�G��b�ֺ n�&�      8    n   x�34�06026242�4370554���4D6�47�,.�O�,�4�0�b�ņ�� ��,-�͍͍L�J�!��fFf�Ț�\�wa�����Q�v\������� ǁ/�      ;    o   x�3���4���+(-Q(K�)M�4�2	q:g�&g+$�g�L@b&��9��)@�)�o�霘����X1��q�d�(�A3��čQŁ� a�
 �1z\\\ �%u      <    �   x���=
�@�z�� �����	���V�4��RS�H�D�3��Qf�B ݰ��robSW�㩒O,X�
�|��x�c�g�d5a��K�����>	��[�}�Q�6�MJ8�p��|���2�Y`;q��-���
�oYʕ�݆Q|�#�h�      =       x������ � �      >       x������ � �      ?    [  x��W�kG>��
A�-o~���T%T�����VE���-���B�%�S��)���,������������H�n,���
�fw�7��}��fB�b��N��M؜�F6Jw�N}�v��A�����89GL3:a�Ƃ�ƌ <n��M&5c<���nF�z#���i����Ha9���F��l쏆;	L:��R�p�Y�x��N/Ӝ��֦���Y���ڰ�ؼ�Г��6��9F���NK���RIYPi{(yT����q�spr'���U�Y��F�&���lo "���9�5R���b�K�[�iw$����:X˜1Z9U�n.�����)�	���ѧ���u���W�N6�KeZ����p�2$g@?j?=�J��&] d���
�g"�n<:ٹ�G:��vN�r �9G�Z�%E���-��C�| θ�ځh.�����������Q锴ʒ�ܠT�]�@a'�j�z{���dZ�_�{�-�+i�����v	�+z+�4W"'e��=��̪�J��\Ȑ�pq�|��U�m�����s���Ne��1R�'���lBI�����Vw���"����BE�����ɑ�w���������W9y�Ǳ��z�`l �V��elu�o�V����v����a�s��[��ˉA�wFýzX�-s-C1�+G�aΤ�/��,��
��.�.��Y2��̨�eDÒ��!5=3�������Wu�\M��%<�W�eAs=5� ����s���ҿ�
b��b�f
Ē��l���{��a:Hݬu��0$�&9� ";׷־K�	j�"V�+,_�~��/����K��Acz�̡R΂G�ַo$���C����
�������� ��=Za�:� �3<���\�Rwo2�v&/�7*J�V����ؿ]Ů�k��n*[����8 ����:M8-2�	FO~�o��T*Hd�A� ��?a�g;o�	�0uc�S��2&!ݐ<	�BG�<�T5i0�ZL��
23�������O	w�C�����;� ��\���6k-`��;�Q?W*��9a��FYG�6��/�yɵ�����<y�{��?W9��׵Z�?q�      @       x������ � �      A       x������ � �      B       x������ � �      C       x������ � �      D       x������ � �      E       x������ � �      F       x������ � �      G    '  x�UнN1�9�}d'v� ��D��p�,,L��g@H�x��Pэ��F�>@�5�����#:�B�� G2ӡA�O�\7���~6/����ч�����j��ZW���=����P��댾�R���;]�c�ł���89�1����6�� �Y�1)�[���_�xO)>���1���'��u]^�;lڒ��D&��ѻÉ9.򛞊��`!6job���$��;�F�f<����gF�n���Q����n�4f���������o~���bv9�Ni��ӭ,�~����      H    O  x�]�=NAF��S�Ȟ��3 !�Hh�"�@P*΀� q���HG?{#��I&�O�=�,FE������A��^��IBuuyx|sYa���A���4L_��K�"Ct��,��Ȍ���)�i�~�GVx�2�+;d�
e��4N�4i��4�+���!�c� �R,1��Q�X(�Ҹ����cی�Чm�n��Ќc��	��\��0���sc;����-��v;�\P`
��Fp�knsPH��>-���w����&G��L^��6&����~�s��a�d�F�$�.1Y�b��',�"{ {FE�5F��&������k[���;u]� �R      I       x������ � �      J    �   x�3���4����1!�FsB �8��"$
� 
��8�}FH
a*��]���X�����ih�E-�4�y�IE�)������qzV��]X����LC$ ��Y�P�XT��Z2���:�	��:F��� �G�      K       x������ � �      L       x������ � �      M       x������ � �      2       x������ � �      N       x������ � �      O       x������ � �      P       x������ � �      Q       x������ � �      R       x������ � �      3       x������ � �      S       x������ � �      T       x������ � �      U       x������ � �      V       x������ � �      W    �   x����J1�s�)�%���Kx�7�(>�Z����R(��W��b]��7r�ja/5�0���P��d�}�Q���J�@�"���!EgY5�]�Logw�?��^k�7d��r�:�~����Mb�ɚ���4%���]vA�0E��46hJ]�h�]� ��_��h4)<a�olK-v�\☳Db8��Ӄ�E?I�xX',q@[��k�G+��G4G�s�K�N��D=������&���~ �C�3      X       x������ � �      Y       x������ � �      Z       x������ � �      [       x������ � �      \       x������ � �      ]       x������ � �      ^       x������ � �      _       x������ � �      `    �   x�m�1N1Ek�)r��{��("XAC�!
�$
�(��4i((W��UP�+|��4i��F���'5>Tx�K����=����;��i���f/��P��Z�):|b���8�t$#�y�+�K�2�F�މ�̖){��̋,��&��b�#�ޜ�^]&��e�u`�Ql���N�G�
o��e�*Ѻ4�6M+C��{��D��sr�*|`��j�>=��æi~�Gz�      a      x�m�AJAE�3��	�������"�� 
#�Bq�;W�q�r0e�jnd�Đ	�k>����C�*	s$�XL�,n���]U��^��Ok�{���ľ���u$c"����D���Vș9	!�q�K7��ޭ�'I2k��}�N� ��G�i�Q����R��H�H���mF���lmm�(������	a�������zry1;�����C�ipʐ�>�ի�o�d�-l��=
�!%�H��j����(�,FQo��?����ϟ�e����      b    �   x�U�;
�@E�Uda~��&�,!EP,���`���O@����?���{��F)�SN�x�`����1�֒�lT,f��aU��I5-�kƅ������?XZ#Xo�&�>,�
-����%i�vNe\I���/�1�S�F�ָ�C|�7���9�.M�������)��ZEV8      c    o   x�3���t��N=��Ӑ�����N,*�LN
�8�K�R�Ss�"& �P�Ђ�ĒD��D���#��y@Cs#3KcK#C#SCC3�ZN�<��̼T��=... ��d      d    �   x�3���4�,.�O�,2.̺��b�H�Ex�ņ�Mv\l����$m�$=�¾����ξ���.�$�/쿰hFӅ
���@^;P�^.Cs#3KcK#C#SCCsSS��P�M�L��)�d�r��qqq �+K�      e       x������ � �      f    {   x�m̱�@���n
&�l���� H�Y&VH��|az���5�ICV'26+˹�����;�x��-�'��jd �H���;24���Ygv�I���q����_IUPT��,�e��~��7F      g    _   x�M��	�@C��b�d{�ib+H�uę�e�!�˂��;��ug�m�h�������f@;��0鰲�9b~,�9��t�X����}��&P      h    t   x�34��025641�42�04531���4D6���,.�O�,�4�0�bㅽ�]�$7(\l���쿰������������������l������i�/�����Ft�b���� �%;      i    �   x�m�;J�A �z�S�a^;;�
��ڦ�H%6I�`!��?>@�濑��˰��3T��D)��H��`r	'g�O���|��;�9{��"db�@���Ȃ���P��[IJ�-(�k���Dw������B[�2�S�e�ݴh��5L��tv��㔴G#	/���9���͸ʟ�1���2��sx�~?4r���%)��v�AEoiT'Ԩ&��5��������fD{�ѭj�6�`�-�?q2����i7      j    H   x�347410671� ����3Ə��������_�w��b�]6(\�sa߅��/ξ��Ӑ+F��� �"�      k    H   x�=���0�3�^̧	W���R���	7f$�Q�r�{Q�Eg�]�;J�=��J���`�zU})�      l    S   x�347410671�3 �3Ə�U�������(>���Ӑ����_�w��b�]6(\�sa߅��/ξ��+F��� `J �      m       x������ � �      n       x������ � �      o       x������ � �      p       x������ � �      q    �   x�M�AJ�A�u��Hf��L.�	zuQ�
]H)"x�������Ffl����{y�Zn�\�27��V��[�8�'�p�a\��t�M�ss+�Wg¦?��=>��s��������	�=��"3��]b�dbچS�����Bi+Y�ٮi���K����%VՓF��F��7N}�TUK�B�.6T%�Ċ���Y�M���b=      r    �   x�U�AJD1���a�i�4��'p�ƕ;u!n""^`PFd�WHod^�dV����˟ K�ȹ$J�V�NB\4������:@�7���lo���x/��E��f�\�k^ڝ��־l;jʪ����>6t�M���[�6C 	��V'��	�m���"�')�(���8����kO������BeD���N�i��o��x��{I����g��"��s?��^��"��p���      s    �   x�U�MJ�1��ur��@�#3���+OPq)nZ\��#�݊�~��^a��Ҡ����I���]�W@c��<Ix��D�zuz~�J��.>b���&��Q+U@�jD�8� N�܎�c����v�^Qgra�Sz/�T屝����ą�k[ށ!����C�6b���6�vs�ڪ���~(�������r-�������l�yy�s�:bn�      t    s   x�u�;A �:�L�����\� �,,34�!눆�EGU7�0�LFXv�? �z:�@fJj�)�@��{0;Kg!q�1���g^�Y�z���k�y�׼���-���r)      u    j   x�E��AC��L16`��T��בQ��rB_փ��Y�[Bi]��[f��U���v�����^4��Śs�c��Ͳ�Q�����p�x7��uW����<�z��?ڬ ,      v    {   x�34�0605573��03770�4���4D6��42�,.�O�,�4�0�bㅽ�]�$7(\l���bÅ[.l�247410�022721621150��*lhbn�d����&n��Ӽ=... ��=�      w    6   x�34�027471137406332���������0�¾{.l���Ӑ+F��� #x`      x       x������ � �      y    D   x�34�0274711374153054���4D606332��,.�O�,�4�0�¾{.l���+F��� +��      z       x������ � �      |       x������ � �      }       x������ � �      ~       x������ � �             x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �    �   x�}�;�0�9=EO��yxD]@���*�c`gfab�R���΍HS6$�D��q,�D�F�F2@Ŧ�q5�+�g��+�'{~tU�[,�a'd&{���X$�z=\��6��zc�C�`��h���rU��؇C8r�y�*�G��(eRv^�p_}�+k����a�*E���{�����E9|���?�}��A�e8x�      �    �   x�}�1NC1�99�;��v.�	*1p�2��e`�܅�5K*�gpn���J��:$��K����3��UKX<��!������2@��}��ׯ5�9��_N}竤�K���8�TAo�f���c��

%PT�ͱ&�4�[k���۾o&�`Q���5_�k]jE�y>l�#����M筯��5ʹ����3k�h��)�ڧ�������C��ۑ�      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      9    �   x�m��1Ekg
���qbg	&�aб=b�Vp6"�Kt��{���4K�){D�i4ع�V��^V6�n������[��N�1ze��G;փݬص�C�c&a�����Ƚ,�"�ω�د[[��ϼ�M�s�y�V�      :    �   x�uα1@�:��	P�ر��D�GE��� @��c�FDAg�O����fI9 D��|e t�v�X�����am7�'v/cW��]J��ש@ȉ0T☑B%�~!�HP�3
#�H�	��[�ac'��Xy��A�C���̄"�꧶D3��? 9�l      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �      �       x������ � �     