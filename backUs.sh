#!/bin/bash
# Configuration file:
source $(pwd)/backUs.cfg

function envia_correo {
  #+------------------------------------------------+#
  #| Envia correo a la persona que se configuro     |#
  #+------------------------------------------------+#
  if [ -n "$EMAIL" ];then
     echo "   /usr/bin/mail -s "Respaldo de $HOSTNAME $FECHA" $EMAIL < $LOG" 
     /usr/bin/mail -s "Respaldo de $HOSTNAME $FECHA" $EMAIL < $LOG

  fi
}


function cambia_permisos {
    #+------------------------------------------------+#
    # Cambia los permisos y dueños de los archivos     #
    #+------------------------------------------------+#
    # Log
    echo "### Cambia permisos de carpetas" 
    #Cambia permisos solo lectura al grupo rwxr-----
    echo  "chmod 740 -R $DIRECTORIOBASE"  
    chmod 740 -R $DIRECTORIOBASE 
    #Cambiar el propietario y grupo de los archivos
    #echo  "chown respaldo.respaldo -R $DIRECTORIOBASE"  
    #chown respaldo.respaldo -R $DIRECTORIOBASE 
    echo  "chown $BKUSER.$BKUSER -R $BASE"  
    chown $BKUSER.$BKUSER -R $BASE

    #Cambia permisos de lectura/escritura al directorio
    echo "chmod 770 $DIRECTORIO"  
    chmod 770 $DIRECTORIO 
}

function crear_directorio {
    #+------------------------------------------------+#
    #| Crea el directorio semanal donde se guardaran  +#
    #| los respaldos realizados			      +#
    #+------------------------------------------------+#
    # Log
    echo "### Crea directorio" 
    #Crea el nuevo directorio
    echo "mkdir -p $DIRECTORIO"  
    mkdir -p $DIRECTORIO 
    echo "mkdir -p $DIRECTORIOAPLIC"  
    mkdir -p $DIRECTORIOAPLIC 
    echo "chmod 777 $DIRECTORIOBASE"  
    chmod 777 $DIRECTORIOBASE 
    echo "chmod 777 $DIRECTORIO"  
    chmod 777 $DIRECTORIO 

}

function bzr_git_respalda {
   #+-------------------------------------------------+#
   #| Accede al codigo fuente para ponerlo en bazaar  |#
   #| crea un compreso del sistema y lo guarda        |#
   #+-------------------------------------------------+#
   APLICACION=$1
   NOMBRE=$2
   CVS=$3
   USUARIO=$4
   echo "** CVS=$CVS"

   # Log
   echo "### Respalda Aplicacion: $APLICACION"   
   #Ingresa  a directorio 
   echo "cd  $APLICACION"  
   cd  $APLICACION 
   #Sino ha sido inicializado el gestor de cambios
   echo "$APLICACION/.$CVS"  
   if ! [ -d "$APLICACION/.$CVS" ] && [ -n "$USUARIO" ]; then
	echo "su  $USUARIO -c  \"$CVS init\""  
	su  $USUARIO -c "$CVS init"
   else
	if ! [ -d "$APLICACION/.$CVS" ]; then
	   echo "$CVS init"  
 	   $CVS init
	fi
   fi

   # Si la ruta y usuario estan definidos, usa el usuario para hacer commit, sino lo hace root
   if [ -n "$APLICACION" ] && [ -n "$USUARIO" ]; then 
        #Agrega archivos nuevos
        echo "su $USUARIO -c \"$CVS add\""  
        su  $USUARIO -c  "$CVS add" 
        #Guarda los cambios de las aplicaciones
        echo "su $USUARIO -c \"$CVS commit -m 'Commit del $FECHA, semana numero $SEMANA'\""  
        su  $USUARIO --command="$CVS commit -m 'Commit del $FECHA, semana numero $SEMANA'" 
   else
     if [ -n "$APLICACION" ];then
        #Agrega archivos nuevos
        echo "$CVS add ."  
        $CVS add .
        #Guarda los cambios de las aplicaciones
        echo "$CVS commit -m 'Commit del $FECHA, semana numero $SEMANA'"  
        $CVS commit -m "Commit del $FECHA, semana numero $SEMANA" 
     fi
   fi
   #Si esta definida esa variable bzr server, lo envia, sino lo guarda en DIRECTORIOAPLIC
   if [ -n "$RUTABAZAAR" ] &&  [ -n "$USUARIO" ] ;then
	#Enviar los respaldos a un repositorio bazar(No indispensable)
	echo "$CVS push $RUTABAZAAR"  
	su  $USUARIO --command="$CVS push $RUTABAZAAR" 
   else
        if [ "$CVS" = "git" ];then

	     if [ ! -d "$DIRECTORIOAPLIC/$NOMBRE" ]; then

		echo "$CVS clone . $DIRECTORIOAPLIC/$NOMBRE "
		$CVS clone . $DIRECTORIOAPLIC/$NOMBRE 
	     else
		echo "cd  $DIRECTORIOAPLIC/$NOMBRE"  
		cd  $DIRECTORIOAPLIC/$NOMBRE
		echo "$CVS pull  $APLICACION master"  
		$CVS pull $APLICACION master
	     fi
	else
	   if [ -n "$RUTABAZAAR" ];then
	     echo "$CVS push $RUTABAZAAR"  	
	     $CVS push $RUTABAZAAR 
	   else
             echo "$CVS push $DIRECTORIOAPLIC/$NOMBRE"  
             $CVS push $DIRECTORIOAPLIC/$NOMBRE 
	   fi
	fi
	
   fi
   # Si el nombre de la aplicacion esta definido, lo comprime y lo guarda
   #Hacemos respaldo de la informacion
   if [ "$NOMBRE" = "adacad" ] && [ "$ACCION" = "completo"  ];then
      echo "tar -jcvf $DIRECTORIO/$FECHA.$NOMBRE.$UNIDAD.aplic.tar.bz2 $APLICACION"  
      tar -jcvf $DIRECTORIO/$FECHA.$NOMBRE.$UNIDAD.aplic.tar.bz2 $APLICACION
   fi

}





function respalda_aplic {
    #+------------------------------------------------+#
    #| Lee las variables de aplicacion a respaldar    |#
    #| y los genera en un archivo                     |#
    #+------------------------------------------------+#

  # Log
  echo "### Inicia respaldo: Aplicaciones variables"  
  #inicializa las variables locales a utilizar
  CUENTAAPLIC=1
  APLICVAR=0
  APLICUSERVAR=
  APLICNAMEVAR=
  APLICCVSVAR=

  while [  -n "$APLICVAR" ]; do
     #Accede a la variables establecidas en la configuracion
     #Ruta aplicacion APLIC{numero}
     VARIABLE=`echo APLIC$CUENTAAPLIC`
     eval APLICVAR=\$$VARIABLE

     #Nombre de la aplicacion APLICNAME{numero}
     VARIABLE=`echo APLICNAME$CUENTAAPLIC`
     eval APLICNAMEVAR=\$$VARIABLE

     #Usuario aplicacion APLICUSER{numero}
     VARIABLE=`echo APLICUSER$CUENTAAPLIC`
     eval APLICUSERVAR=\$$VARIABLE

     #Usuario aplicacion APLICCVS{numero}
     VARIABLE=`echo APLICCVS$CUENTAAPLIC`
     eval APLICCVSVAR=\$$VARIABLE

     echo "**APLICVAR - APLICNAMEVAR - APLICUSERVAR - APLICCVSVAR :  VARIABLES"
     echo "** $APLICVAR - $APLICNAMEVAR - $APLICUSERVAR - $APLICCVSVAR : $APLICCVSVAR"

     #Verifica que el nombre y ruta de aplicacion esten definidas
     if [ -n "$APLICVAR" ] && [ -n "$APLICNAMEVAR" ];then
  	bzr_git_respalda $APLICVAR $APLICNAMEVAR  $APLICCVSVAR $APLICUSERVAR
     fi
     
     let CUENTAAPLIC+=1

  done
  # Log
  echo "### FIN respaldo: Aplicaciones variables"  
}



function respaldar {
    #+----------------------------------------------+#
    #| Aun carece de validaciones esta seccion, mas |#
    #| es esta seccion donde puede cambiar el metodo|#
    #| de compresion, y si es asi debe tomarse en   |#
    #| cuenta que el firmado y la comparacion seran |#
    #| alterados tambien actaulmete se esta usando  |#
    #| bzip2 pero 7z y lzma comprimen mas qeu bzip  |#
    #| pero solo lzma trae un lzcat para sustituirle|#
    #| Falta agregarle la funcion para respaldar    |#
    #| tanto POSTGRES como MYSQL                    |#
    #+----------------------------------------------+#
    BASELOCAL=$1
    USUARIODB=$2
    CLAVEDB=$3
    TYPODB=$4
    # Log
    echo "### Respalda DB $BASELOCAL"  
    # entrar a la carpeta donde se genera el respaldo
    echo "cd $DIRECTORIO"  
    cd $DIRECTORIO 


   ## Inicia el respaldo de bases de datos de POSTGRESQL
    if [ "$TYPODB" = "postgres" ];then

	#Respalda todas las bases de postgres 	
	if [ "$BASELOCAL" = "todopostgres" ];then
           # Cleaning and optimization for all DB except templates and postgres
           for DBN in $(su postgres -c "psql  -t -A  -c 'SELECT datname FROM pg_database' | egrep -v  '(template|postgres)' ") ; do
             echo "su postgres --command=\"/usr/bin/vacuumdb -d $DBN -z\" "  
             su postgres -c "/usr/bin/vacuumdb -d $DBN -z"
           done
	
	   # Respalda todas las bases de datos de postgres
	   echo "su postgres -c \"pg_dumpall \" | bzip2 -c > $FECHA.$BASELOCAL-$UNIDAD.$ACCION.bz2"  
           su postgres -c "pg_dumpall " | bzip2 -c > $FECHA.$BASELOCAL-$UNIDAD.$ACCION.bz2
        else 


	  # Limpieza y optimización de la base de datos
	  echo "su postgres --command=\"/usr/bin/vacuumdb -d $BASELOCAL -z\" "  
	  su postgres -c "/usr/bin/vacuumdb -d $BASELOCAL -z" 
	  # dumpeado y compresion directa de la base de datos
          if [ -n "$USUARIODB" ] && [ -n "$CLAVEDB" ]; then # Si usuario y clave estan establecidos, los usa, sino el usuario postgres
   	    echo "export PGPASSWORD=$CLAVEDB" 
	    export PGPASSWORD=$CLAVEDB 
	    echo " su postgres -c \"pg_dump --host $SERVIDOR --username=$USUARIODB $BASELOCAL\" | bzip2 -c > $FECHA.$BASELOCAL-$UNIDAD.$ACCION.bz2"  
	    su postgres -c "pg_dump --host $SERVIDOR --username=$USUARIODB $BASELOCAL" | bzip2 -c > $FECHA.$BASELOCAL-$UNIDAD.$ACCION.bz2 
	  else
	    echo "su postgres -c \"pg_dump $BASELOCAL\" | bzip2 -c > $FECHA.$BASELOCAL-$UNIDAD.$ACCION.bz2"  
	    su postgres -c "pg_dump  $BASELOCAL" | bzip2 -c > $FECHA.$BASELOCAL-$UNIDAD.$ACCION.bz2  
	  fi
	fi
    fi # Fin de respaldo de postgresql

    ## Inicia el respaldo de base MYSQL
    if [ "$TYPODB" = "mysql" ];then
	# Optimizacion de la base datos
	echo " mysqloptimize  -A -a -c -p(clavesecreta)"  
	mysqloptimize  -A -a -c -p$CLAVEDB

	# Respalda todas las bases de datos de mysql
	if [ "$BASELOCAL" = "todomysql" ] && [  -n "$CLAVEDB" ];then
	   echo " mysqldump --all-databases -p(clavesecreta)  | bzip2 -c > $FECHA.$BASELOCAL-$UNIDAD.$ACCION.bz2" 
	   mysqldump --all-databases -p$CLAVEDB  | bzip2 -c > $FECHA.$BASELOCAL-$UNIDAD.$ACCION.bz2
	else 
	  if [ -n "$USUARIODB" ] && [ -n "$CLAVEDB" ]; then # Si usuario y clave estan establecidos, los usa, sino el usuario postgres
	   echo " "
	   mysqldump $BASELOCAL -p$CLAVEDB | bzip2 -c > $FECHA.$BASELOCAL-$UNIDAD.$ACCION.bz2
	  fi
	fi
    fi # Fin de respaldo de mysql

    # Log
    echo "### FIN Respalda DB $BASELOCAL"  

}



function firmar {
    BASELOCAL=$1
    ENLACEFIRMALOCAL=$BASELOCAL-$UNIDAD.FirmaActual
    ARCHIVOFIRMALOCAL=$FECHA.$BASELOCAL-$UNIDAD.$ACCION.rfirma
    # Log 
    echo "### Firma archivo $BASELOCAL"  
    # Crear Firma de Archivo Base
    echo "bzcat $FECHA.$BASELOCAL-$UNIDAD.$ACCION.bz2 | rdiff signature > $ARCHIVOFIRMALOCAL"  
    bzcat $FECHA.$BASELOCAL-$UNIDAD.$ACCION.bz2 | rdiff signature > $ARCHIVOFIRMALOCAL
    # borrado del enlace viejo del la Firma Base
    echo "rm -fv $ENLACEFIRMALOCAL"  
    rm -fv $ENLACEFIRMALOCAL 
    # enlazado de la nueva Firma Base
    echo "ln -s $ARCHIVOFIRMALOCAL $ENLACEFIRMALOCAL"  
    ln -s $ARCHIVOFIRMALOCAL $ENLACEFIRMALOCAL 
}

function diferenciar {
    BASELOCAL=$1
    ENLACEFIRMALOCAL=$BASELOCAL-$UNIDAD.FirmaActual
    ARCHIVODELTALOCAL=$FECHA.$BASELOCAL-$UNIDAD.$ACCION.rdelta.bz2

    #Log
    echo "### Diferenciar $BASELOCAL"  
    # Crear Archivo Delta
    echo "bzcat $FECHA.$BASELOCAL-$UNIDAD.$ACCION.bz2 | rdiff delta $ENLACEFIRMALOCAL | bzip2 -c > $ARCHIVODELTALOCAL"  
    bzcat $FECHA.$BASELOCAL-$UNIDAD.$ACCION.bz2 | rdiff delta $ENLACEFIRMALOCAL | bzip2 -c > $ARCHIVODELTALOCAL
    # Borrar Archivo Grande Compreso
    echo "rm -fv $FECHA.$BASELOCAL-$UNIDAD.$ACCION.bz2"  
    rm -fv $FECHA.$BASELOCAL-$UNIDAD.$ACCION.bz2 
}

#Verifica que existenn las aplicaciones
function prueba_aplicacion {
  #+------------------------------------------------+#
  #| Lee el argumento, y verifica que existan las   +#
  #| aplicaciones para ejecutarlas                  +#
  #+------------------------------------------------+#

   APLICACION=$1
   # Test de $APLICACION
   if [  -e $APLICACION ]
   then
     echo "$APLICACION: instalado" >> /dev/null
   else
     echo "No existe $APLICACION"  
     ERROR="true"
   fi
}




#####################
# FUNCION PRINCIPAL #
#####################

#Registro de la hora de inicio
date  

#--------------------VERIFICA PROGRAMAS-------------------------------------#
# Test de la base de datos
# prueba_aplicacion /usr/bin/pg_dump
# prueba_aplicacion /usr/bin/mysqldump
# Test de rdiff
 prueba_aplicacion /usr/bin/rdiff
# Test de bzr
 prueba_aplicacion /usr/bin/bzr
# Test de git
 prueba_aplicacion /usr/bin/git
# Test de bzip2
 prueba_aplicacion /bin/bzip2
# Test de email
 prueba_aplicacion /usr/bin/mail
# Lee la variable de Error
if [ "$ERROR" = "true" ];then

   echo "ERROR:Verifique los logs $LOG para ver detalles del error" 
   echo "ERROR:Verifique los logs $LOG para ver detalles del error"  
   exit 1
fi

#---------------------------------------------------------#

  # Log
  echo "### Inicia respaldo: Variable"  
  #inicializa las variables locales a utilizar
  CUENTA=1
  DBVAR=0
  DBUSERVAR=
  DBPASSVAR=

#Crear los directorios si es necesario
crear_directorio

  while [  -n "$DBVAR" ]; do
     #Accede a la variables establecidas en la configuracion
     #Base de datos DB{numero}
     VARIABLE=`echo DB$CUENTA`
     eval DBVAR=\$$VARIABLE

     #Base de datos DBUSER{numero}
     VARIABLE=`echo DBUSER$CUENTA`
     eval DBUSERVAR=\$$VARIABLE

     #Base de datos DBPASS{numero}
     VARIABLE=`echo DBPASS$CUENTA`
     eval DBPASSVAR=\$$VARIABLE

     #Tipo de Base de datos DBTYPE{numero}
     VARIABLE=`echo DBTYPE$CUENTA`
     eval DBTYPEVAR=\$$VARIABLE


     #Verifica que exista la firma para hacer un diferencial
     if [ -n "$DBVAR"  ];then
	ENLACEFIRMA=$DBVAR-$UNIDAD.FirmaActual
	TEST=$DIRECTORIO/$ENLACEFIRMA
     fi
     if test -f $TEST; then

        echo "Existe $DIRECTORIO/$ENLACEFIRMA"
        ACCION="diferencial"
     else

        echo "NO Existe $DIRECTORIO/$ENLACEFIRMA" 
        ACCION="completo"
     fi


     #Verifica que la variable exista
     if [ -n "$DBVAR" ]; then
	    case $ACCION in
	        completo)
		     # Log
		    echo "#---------------------------------#"  
	            echo "#  RESPALDO COMPLETO $DBVAR #" 
	            echo "#---------------------------------#" 
	            respaldar $DBVAR $DBUSERVAR $DBPASSVAR $DBTYPEVAR
	            firmar $DBVAR
	        ;;
	        diferencial)
		    # Log
		    echo "#---------------------------------#" 
	            echo " RESPALDO DIFERENCIAL $DBVAR"  
	            echo "----------------------"  
	            respaldar $DBVAR $DBUSERVAR $DBPASSVAR $DBTYPEVAR
	            diferenciar $DBVAR
	        ;;
	        *)
	            echo "++No se ejecuto ni Completo ni Diferencial" 
	            exit 1
	        ;;
	    esac
     fi
     let CUENTA+=1
  done

#respaldamos las aplicaciones
respalda_aplic
# Regresa los permisos de las carpetas
cambia_permisos

##########FIN DEL CONTENIDO DEL SCRIPT################
#Registro de la hora finalizada
date  
#Llamo a la funcion de envio de correo
envia_correo
#Rota los logs cada semana
#savelog $LOG >$LOGDIR/$NOMBRESCRIPT.log.0

