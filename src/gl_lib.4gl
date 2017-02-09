
IMPORT os

PUBLIC DEFINE m_ui BOOLEAN
PUBLIC DEFINE m_logDir STRING
PUBLIC DEFINE m_logName STRING
PUBLIC DEFINE m_logDate BOOLEAN

FUNCTION gl_init(l_ui)
	DEFINE l_ui BOOLEAN
	LET m_ui = l_ui
	LET m_logdir = gl_getLogDir()
	LET m_logName = gl_getLogName()
	CALL STARTLOG( m_logdir||m_logName||".err" )
END FUNCTION

----------------------------------------------------------------------------------
#+ Generic Windows message Dialog.  NOTE: This handles messages when there is no window!
#+
#+ @param l_title     = String: Window Title
#+ @param l_message   = String: Message text
#+ @param l_icon      = String: Icon name, "exclamation"
#+ @return none
FUNCTION gl_winMessage(l_title, l_message, l_icon) --{{{
	DEFINE l_title, l_message, l_icon STRING
	DEFINE w ui.window

	IF fgl_getEnv("FGLGUI") = "0" OR NOT m_ui THEN 
		DISPLAY "gl_winMessage:",l_message
		RETURN
	END IF

	LET w = ui.window.getcurrent()
	IF w IS NULL THEN
		OPEN WINDOW dummy AT 1,1 WITH 1 ROWS, 2 COLUMNS
	END IF

	MENU l_title ATTRIBUTES(STYLE="dialog",COMMENT=l_message, IMAGE=l_icon)
		COMMAND "Okay" EXIT MENU
	END MENU

	IF w IS NULL THEN
		CLOSE WINDOW dummy
	END IF

END FUNCTION --}}}
--------------------------------------------------------------------------------
-- double use, 1=set m_logdir for THIS function, 2=set&return logdir to call programming
-- also check for and create the log folder if it doesn't exist.
--	normally not required as it's created during package install.
FUNCTION gl_getLogDir()
	LET m_logDir = fgl_getEnv("LOGDIR")
	LET m_logDate = TRUE
	IF fgl_getEnv("LOGFILEDATE") = "false" THEN LET m_logDate = FALSE END IF
	IF m_logDir.getLength() < 1 THEN
		LET m_logDir = "../logs/" -- default logdir
	END IF

	IF NOT os.path.exists( m_logDir ) THEN
		IF NOT os.path.mkdir( m_logDir ) THEN
			CALL gl_winMessage("Error","Failed to make logdir '"||m_logDir||"'.\nProgram aborting","exclamation")
			EXIT PROGRAM 200
		ELSE
			IF NOT os.path.chrwx( m_logDir,  ( (7 *64) + (7 * 8) + 5 )  ) THEN
				CALL gl_winMessage("Error","Failed set permissions on logdir '"||m_logDir||"'.","exclamation")
				EXIT PROGRAM 201
			END IF
		END IF
	END IF
	IF NOT os.path.isDirectory( m_logDir ) THEN
		CALL gl_winMessage("Error","Logdir '"||m_logDir||"' not a directory.\nProgram aborting","exclamation")
		EXIT PROGRAM 202
	END IF

# Make sure the logdir ends with a slash.
	IF m_logDir.getCharAt( m_logDir.getLength() ) != os.path.separator() THEN
		LET m_logDir = m_logDir.append( os.path.separator() )
	END IF
	RETURN m_logDir
END FUNCTION
--------------------------------------------------------------------------------
-- get / set m_logName 
-- NOTE: doesn't include the extension so you can use it for .log and .err
FUNCTION gl_getLogName()
	DEFINE l_user STRING
	IF m_logName IS NULL THEN
		LET l_user = fgl_getEnv("LOGNAME") -- get OS user
		IF l_user.getLength() < 2 THEN
			LET l_user = fgl_getEnv("USERNAME") -- get OS user
		END IF
		IF l_user.getLength() < 2 THEN
			LET l_user = "unknown"
		END IF
		--LET m_logName = (TODAY USING "YYYYMMDD")||"-"||base.application.getProgramName()
		IF m_logDate THEN
			LET m_logName = base.application.getProgramName()||"-"||(TODAY USING "YYYYMMDD")||"-"||l_user
		ELSE
			LET m_logName = base.application.getProgramName()
		END IF
	END IF
	RETURN m_logName
END FUNCTION

--------------------------------------------------------------------------------
#+ Write a message to an audit file.
#+
#+ @param l_mess Message to write to audit file.
FUNCTION gl_logIt( l_mess ) --{{{
	DEFINE l_mess, l_pid,l_fil STRING
	--DEFINE x,y SMALLINT
	DEFINE c base.Channel
	LET l_pid = fgl_getPID()
	--DISPLAY base.application.getProgramName()||": "||NVL(l_mess,"NULL")
	LET c = base.Channel.create()
	IF m_logDir IS NULL THEN LET m_logDir = gl_getLogDir() END IF
	IF m_logName IS NULL THEN LET m_logName = gl_getLogName() END IF
	LET l_fil = m_logDir||m_logName||".log"
	IF base.application.getProgramName() MATCHES "paas*" THEN
		LET l_fil = m_logDir||m_logName||"."||l_pid||".audit"
	END IF
	CALL c.openFile(l_fil,"a")

	LET l_fil = gl_getCallingModuleName()
	IF l_fil MATCHES "cloud_gl_lib.gl_dbgMsg:*" THEN
		LET l_mess = CURRENT||"|"||NVL(l_mess,"NULL")
	ELSE
		LET l_mess = CURRENT||"|"||NVL(l_fil,"NULL")||"|"||l_mess
	END IF
	
	DISPLAY "Log:",l_mess
	CALL c.writeLine(l_mess)

	CALL c.close()
END FUNCTION --}}}
--------------------------------------------------------------------------------
#+ Gets sourcefile.module:line from a stacktrace.
#+
FUNCTION gl_getCallingModuleName()
	DEFINE l_fil,l_mod,l_lin STRING
	DEFINE x,y SMALLINT
	LET l_fil = base.Application.getStackTrace()
	IF l_fil IS NULL THEN
		DISPLAY "Failed to get getStackTrace!!"
		RETURN "getStackTrace-failed"
	END IF
	--DISPLAY "getCallingModuleName ST:",l_fil
	LET x = l_fil.getIndexOf("#",2) -- skip passed this func
	LET x = l_fil.getIndexOf("#",x+1) -- skip passed func that called this func
	LET x = l_fil.getIndexOf(" ",x) + 1
	LET y = l_fil.getIndexOf("(",x) - 1
	LET l_mod = l_fil.subString(x,y)

	LET x = l_fil.getIndexOf(" ",y) + 4
	LET y = l_fil.getIndexOf("#",x+1) - 2
	IF y < 1 THEN LET y = (l_fil.getLength() - 1) END IF
	LET l_fil = l_fil.subString(x,y)

-- strip the .4gl from the fil name
	LET x = l_fil.getIndexOf(".",1)
	IF x > 0 THEN
		LET y = l_fil.getIndexOf(":",x)
		LET l_lin = l_fil.subString(y,l_fil.getLength())
		LET l_fil = l_fil.subString(1,x-1)
	END IF
	--DISPLAY "Fil:",l_fil," Mod:",l_mod," Line:",l_lin
	LET l_fil = NVL(l_fil,"FILE?")||"."||NVL(l_mod,"MOD?")||":"||NVL(l_lin,"LINE?")
	RETURN l_fil
END FUNCTION --}}}