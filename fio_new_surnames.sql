-- Function: fio_new_surnames()

-- DROP FUNCTION fio_new_surnames();

CREATE OR REPLACE FUNCTION fio_new_surnames()
  RETURNS void AS
$BODY$DECLARE r record;

ends_arr text[][] := '{{"ов","ова"},{"ев","ева"}, {"ин","ина"}, {"иев", "иева"}, {"кий", "кая"}}';

m_ends_arr text[][] := '{{"ович","овна"},{"евна","евич"}}';

total int := 0;
names_total int := 0;
midnames_total int := 0;
x int;
y int;
oname text;
BEGIN
  update tmpload_fio set sex = 'm' where sex = lower('м');
  update tmpload_fio set sex = 'w' where sex = lower('ж');

  for r in (select * from tmpload_fio) 
  LOOP
    if lower(r.t) = 'ф' then
      if not exists (select surname from people_surnames where lower(surname) = lower(r.name)) then
        insert into people_surnames (surname) values (r.name);
        raise notice 'Новая фамилия: %', r.name;
        total := total + 1; 
      end if;
      for x in 1..array_length(ends_arr, 1) loop
        for y in 1..2 loop
          if r.name ~ ('^.+' || ends_arr[x][y] || '$') then
            oname := substring(r.name from 1 for (length(r.name) - length(ends_arr[x][y]))) || (case when y = 1 then ends_arr[x][2] else ends_arr[x][1] end);
            if not exists (select surname from people_surnames where lower(surname) = lower(oname)) then 
              insert into people_surnames (surname) values (oname);
              raise notice 'Новая фамилия: % (%)', oname, r.name;  
              total := total + 1; 
            end if;
          end if;           
        end loop;
      end loop;
    elsif lower(r.t) = 'и' then
      if not exists (select people_name from people_names where lower(people_name) = lower(r.name)) then
        insert into people_names (people_name,sex) values (r.name,r.sex);
        raise notice 'Новое имя: % %', r.name, r.sex;
        names_total := names_total + 1; 
      end if;    
    elsif lower(r.t) = 'о' then
      if not exists (select midname from people_midnames where lower(midname) = lower(r.name)) then
        insert into people_midnames (midname) values (r.name);
        raise notice 'Новое отчество: %', r.name;
        midnames_total := midnames_total + 1; 
      end if;        
      
      for x in 1..array_length(m_ends_arr, 1) loop
        for y in 1..2 loop
          if r.name ~ ('^.+' || m_ends_arr[x][y] || '$') then
          
            oname := substring(r.name from 1 for (length(r.name) - length(m_ends_arr[x][y]))) || (case when y = 1 then m_ends_arr[x][2] else m_ends_arr[x][1] end);
            if not exists (select midname from people_midnames where lower(midname) = lower(oname)) then 
              insert into people_midnames (midname) values (oname);
              raise notice 'Новое отчество: % (%)', oname, r.name;  
              midnames_total := midnames_total + 1; 
            end if;

            oname := substring(r.name from 1 for (length(r.name) - length(m_ends_arr[x][y]) ));
            if not exists (select people_name from people_names where lower(people_name) = lower(oname)) then
              insert into people_names (people_name,sex) values (oname,'m');
              raise notice 'Новое имя: % m', oname;
              names_total := names_total + 1; 
            end if;    
            
          end if;           
        end loop;
      end loop;      
    end if;
  END LOOP;
  raise notice 'Всего внесено % фамилий, % имен, % отчеств', total, names_total, midnames_total;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fio_new_surnames()
  OWNER TO kladr;
COMMENT ON FUNCTION fio_new_surnames() IS 'Вносит новые фамилии из таблицы tmpload_fio';
