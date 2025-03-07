CREATE TABLE `layoffsstaging` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
insert  into layoffsstaging 
select * from layoffs;

with duplicate_cte as
(select * ,
row_number() over (partition by company,industry,total_laid_off,`date`) as rownum from layoffsstaging)
select * from duplicate_cte where rownum>1;

select *from layoffsstaging2;

insert  into layoffsstaging2
select * ,
row_number() over (partition by company,industry,total_laid_off,`date`) as rownum from layoffsstaging;

select* from layoffsstaging2;

delete from layoffsstaging2 where rownum>1;
select company,trim(company)
from layoffsstaging2;
update layoffsstaging2 
set company=trim(company);

update layoffsstaging2 set industry ='crypto' where industry like 'crypto%';
use db;
select * from layoffsstaging2
where total_laid_off is null
and percentage_laid_off;

update layoffsstaging2 set industry=null
where industry='';
update layoffsstaging2 as t1
join layoffsstaging2 as t2
on t1.company=t2.company
set t1.industry=t2.industry
where t1.industry is null
and t2.industry is not null;

select* from layoffsstaging2;

select location, total_laid_off from layoffsstaging2;
use db;
delete from layoffsstaging2
where total_laid_off is null and
percentage_laid_off is null;

alter table layoffsstaging2
drop column rownum;

update layoffsstaging2
set `date`=str_to_date(`date`,'%m/%d/%Y');

alter table layoffsstaging2
modify column `date` DATE;