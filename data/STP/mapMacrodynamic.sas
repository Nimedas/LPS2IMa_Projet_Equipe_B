* D�but du code EG g�n�r� (ne pas modifier cette ligne);
*
*  Application stock�e enregistr�e par
*  Enterprise Guide Stored Process Manager V6.1
*
*  ====================================================================
*  Nom de l'application stock�e : mapMacrodynamic
*  ====================================================================
*
*  Dictionnaire d'invites de l'application stock�e :
*  ____________________________________
*  SELECT_ENSEIGNE
*       Type : Num�rique
*      Libell� : SELECT_ENSEIGNE
*       Attr: Visible
*  ____________________________________
*  SELECT_REGIONCOM
*       Type : Num�rique
*      Libell� : SELECT_REGIONCOM
*       Attr: Visible
*  ____________________________________
*;


*ProcessBody;

%global SELECT_ENSEIGNE
        SELECT_REGIONCOM;

* Fin du code EG g�n�r� (ne pas modifier cette ligne);


%global select_enseigne;
%global select_regioncom;
*ProcessBody;
data _null_;
rc=stpsrv_header('Cache-Control','no-cache');
rc=stpsrv_header('Pragma','no-cache');
rc=stpsrv_header('Content-Type','image/png');
run;
libname ORA12015 meta library="ORA-DARTIES1-2015";
%stpbegin;
/*Import de la carte de france : */
PROC MAPIMPORT DATAFILE='D:\sasuserdirs\projets\DARTIES1-2015\shapefiles-2015\topo_dept.shp'
OUT=franceDb2015;
run;

/*Import des donn�es des villes (coordonn�es x et y des villes) : */
PROC MAPIMPORT DATAFILE="D:\sasuserdirs\projets\DARTIES1-2015\RGC_2015_geom.shp"
   OUT=rgc_2015_sas;
   run;


/*Jointure entre la table rgc (donn�es des villes) 
 et la table france_departements pour avoir la region com des villes  */
proc sql;
create table work.francedb2015Com as
select *
from work.rgc_2015_sas rgc, ORA12015.france_departements f_d
where rgc.dep = code_dept; 
quit;
run;


/* macro fonction qui g�n�re une carte au format png, avec une enseigne et une region com
, 0 repr�sente toutes les r�gions ou enseignes */
%macro mapPng(idEnseigne, idRegionCom);

/*config pour la g�n�ration des r�sultats :*/
*ods _all_ close ;
*ods listing;
GOPTIONS device=png xpixels=500 ypixels=450;



/*
filename gout "P:\e_15_darties1\private_html\map_sas\map_enseigne&idenseigne._regioncom&idRegionCom..png";
*/

/*Proc sql pour garder seulement les magasins n�cessaires pour la carte, 
elle change en fonction des valeurs des param�tres : */

%if &idEnseigne. = 0 and &idRegionCom. = 0 %then %do;
/* pas de condition sur l'ensiegne ou sur la region com
car idEnseigne = 0 et idRegion = 0*/
proc sql;
create table work.annoMag as
select nom, x, y, id_enseigne, rgc.dep , id_region_com
from work.francedb2015Com rgc, ORA12015.dim_magasin m
where upcase(rgc.nom) = upcase(m.ville); 
quit;
run;

%end;
%else %if &idEnseigne. = 0 and (&idRegionCom. =1 or &idRegionCom. =2 or &idRegionCom. =3 or &idRegionCom. =4 or &idRegionCom. =5) %then %do;
/*Condition sur la region com si elle n'est pas �gal � 0 (1,2,3,4 ou 5) */
proc sql;
create table work.annoMag as
select nom, x, y, id_enseigne, rgc.dep , id_region_com
from work.francedb2015Com rgc, ORA12015.dim_magasin m
where upcase(rgc.nom) = upcase(m.ville)
and id_region_com = &idRegionCom.;
quit;
run;

%end;

%else %if (&idEnseigne. = 1 or &idEnseigne. = 2 or &idEnseigne. = 3) and &idRegionCom. =0 %then %do;
/*Condition sur l'id enseigne si elle n'est pas �gal � 0 (1,2 ou 3) */
proc sql;
create table work.annoMag as
select nom, x, y, id_enseigne, rgc.dep , id_region_com
from work.francedb2015Com rgc, ORA12015.dim_magasin m
where upcase(rgc.nom) = upcase(m.ville)
and id_enseigne = &idEnseigne.;
quit;
run;

%end;

%else %if (&idEnseigne. = 1 or &idEnseigne. = 2 or &idEnseigne. = 3) and (&idRegionCom. =1 or &idRegionCom. =2 or &idRegionCom. =3 or &idRegionCom. =4 or &idRegionCom. =5) %then %do;
/* condition sur les deux si idEnseigne !=0 et id region com != 0*/
proc sql;
create table work.annoMag as
select nom, x, y, id_enseigne, rgc.dep , id_region_com
from work.francedb2015Com rgc, ORA12015.dim_magasin m
where upcase(rgc.nom) = upcase(m.ville)
and id_enseigne = &idEnseigne.
and id_region_com = &idRegionCom.;
quit;
run;

%end;

/*g�n�rer un data set d'annotation pour afficher les logos des enseignes sur la carte
, on utilise le r�sultat de la proc sql (work.annoMag) pour placer les logos sur la carte*/
data annoVille;
	length function color $ 8 position $ 1
    text $ 20 style $ 30; 
    retain xsys ysys '2' hsys '3' when 'a';
    set work.annoMag;

	/*r�duction des logos pour la r�gion parisienne : */
	%if &idRegionCom. =5 %then %do;

	x=x-17000.01;
    y=y-8200.01;
    function='move';
    output;
        	
    x=x+17000.01;
    y=y+8200.01;
    function='image';
    style='fit';

	%end;
	%else %do;
	x=x-37000.01;
    y=y-28200.01;
    function='move';
    output;
        	
    x=x+37000.01;
    y=y+28200.01;
    function='image';
    style='fit';
	%end;


	/*Utilisation du logo en fonction de l'id Enseigne : */
    if ID_ENSEIGNE = 1 then do;
    imgpath="D:\sasuserdirs\projets\DARTIES1-2015\images\boulanger.png";
    end;
		
    else if ID_ENSEIGNE = 2 then do;
    imgpath="D:\sasuserdirs\projets\DARTIES1-2015\images\2.gif";
    end;
    else if ID_ENSEIGNE = 3 then do;
    imgpath="D:\sasuserdirs\projets\DARTIES1-2015\images\3.jpg";
    end;
    output;
		
				
run;

/*on termine par la proc gmap pour g�n�rer la carte au format png */

/*Si la carte repr�sente toutes les r�gions com, il n'y a pas de condition pour la proc gmap*/
%if (&idEnseigne. = 0 or &idEnseigne. = 1 or &idEnseigne. = 2 or &idEnseigne. = 3) and &idRegionCom. = 0 %then %do;
proc gmap map=franceDb2015
          data=work.francedb2015com;
   id code_dept ;
   choro id_region_com / anno=work.annoVille discrete nolegend;
   title box=1 f=none h=4
         ;
 /*on d�finit les couleurs des 5 r�gions com avec des pattern color : */
     pattern1 color=CXD0FFFF;
	 pattern2 color=CX7080FF;
     pattern3 color=CXA0C0FF;
	 pattern4 color=CX3040FF;
     pattern5 color=CX000093;

   
run;
quit;
%end;
/*Si la carte repr�sente toutes les r�gions com, il y a une condition dans la proc gmap :*/
%else %if (&idRegionCom. =1 or &idRegionCom. =2 or &idRegionCom. =3 or &idRegionCom. =4 or &idRegionCom. =5)  %then %do;
proc gmap map=franceDb2015
          data=work.francedb2015com;
		  where id_region_com = &idRegionCom.;


   id code_dept ;
   choro id_region_com / anno=work.annoVille discrete nolegend;
   title box=1 f=none h=4
         ;

		 /*En fonction de la r�gion com en param�tre, on d�finit la couleur avec un pattern1 color */
		 %if &idRegionCom. =1  %then %do;
	 		pattern1 color=CXD0FFFF;
		 %end;

		 %if &idRegionCom. =2  %then %do;
		 pattern1 color=CX7080FF;
		 %end;

		 %if &idRegionCom. =3  %then %do;
		 pattern1 color=CXA0C0FF;
		 %end;

		 %if &idRegionCom. =4 %then %do;
		 pattern1 color=CX3040FF;
		 %end;

		 %if &idRegionCom. =5  %then %do;
		 pattern1 color=CX000093;
		 %end;

run;
quit;
%end;
%mend;

/* On utilise la fonction mapPng pour g�n�rer toutes les cartes possibles */
/*id enseigne , id region com*/

%mapPng(%sysfunc(INT(&select_enseigne.)),%sysfunc(INT(&select_regioncom.)));


%stpend;

* D�but du code EG g�n�r� (ne pas modifier cette ligne);
;*';*";*/;quit;

* Fin du code EG g�n�r� (ne pas modifier cette ligne);

