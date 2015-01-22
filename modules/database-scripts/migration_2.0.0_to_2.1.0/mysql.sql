-- Migration Script for AF 2.0.0 to AF 2.1.0 --
-- 1.Create a database for AF runtime DB 
-- 2.Change dbGovernanceCloud to the existing AF GOV REG DB.
-- 3.Change script according to the Stage configuration(For WSO2 Cloud no need to do anything)
-- 4.Run the script against the new DB.
-- 5.If you want to move the AF DB to new databse take dump and restore.

-- Start
CREATE TABLE IF NOT EXISTS AF_APPLICATION (
	ID INTEGER AUTO_INCREMENT,
	APPLICATION_KEY VARCHAR(100) NOT NULL,
	TENANT_ID INTEGER NOT NULL,
	STATUS VARCHAR(100) NOT NULL DEFAULT 'PENDING',
	REG_CONTENT VARCHAR(1000),
	PRIMARY KEY(ID),
	UNIQUE (APPLICATION_KEY,TENANT_ID)
);

INSERT INTO AF_APPLICATION(APPLICATION_KEY,TENANT_ID,REG_CONTENT) SELECT RP.REG_PATH_VALUE, R.REG_TENANT_ID,C.REG_CONTENT_DATA FROM dbGovernanceCloud.REG_CONTENT C, dbGovernanceCloud.REG_RESOURCE R,dbGovernanceCloud.REG_PATH RP WHERE C.REG_CONTENT_ID = R.REG_CONTENT_ID AND C.REG_TENANT_ID = R.REG_TENANT_ID AND R.REG_MEDIA_TYPE = 'application/vnd.wso2-application+xml' AND R.REG_NAME IS NOT NULL AND RP.REG_PATH_ID=R.REG_PATH_ID;

UPDATE AF_APPLICATION
SET STATUS = 'COMPLETED'
WHERE REG_CONTENT NOT LIKE '%<applicationCreationStatus>%' ;
UPDATE AF_APPLICATION
SET STATUS = SUBSTRING(REG_CONTENT,INSTR(REG_CONTENT,'<applicationCreationStatus>') + 27)
WHERE REG_CONTENT LIKE '%<applicationCreationStatus>%' ;

UPDATE AF_APPLICATION
SET STATUS = REPLACE(STATUS,SUBSTRING(STATUS,INSTR(STATUS,'</applicationCreationStatus>')),'')
WHERE STATUS IS NOT NULL;
-- DONE with AF_APPLICATION

CREATE TABLE IF NOT EXISTS AF_VERSION (
        ID INTEGER AUTO_INCREMENT,
        APPLICATION_ID INTEGER NOT NULL,
        VERSION_NAME VARCHAR(100) NOT NULL,
        STAGE VARCHAR(100) DEFAULT 'Development',
        PROMOTE_STATUS VARCHAR(100) NULL,
        REG_CONTENT VARCHAR(1000),
        FOREIGN KEY(APPLICATION_ID) REFERENCES AF_APPLICATION(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
        PRIMARY KEY(ID),
        UNIQUE (VERSION_NAME,APPLICATION_ID)
);

CREATE TABLE IF NOT EXISTS AF_REPOSITORY (
            ID INTEGER AUTO_INCREMENT,
        VERSION_ID INTEGER NOT NULL,
        REPOSITORY_IS_FORK TINYINT DEFAULT 0,
            USER_ID VARCHAR(100) NULL,
        REG_CONTENT VARCHAR(1000),
        FOREIGN KEY(VERSION_ID) REFERENCES AF_VERSION(ID) ON UPDATE CASCADE ON
        DELETE RESTRICT,
        PRIMARY KEY(ID)
);

CREATE TABLE IF NOT EXISTS AF_BUILD (
        ID INTEGER AUTO_INCREMENT,
        REPOSITORY_ID INTEGER NOT NULL,
        CURRENT_BUILD VARCHAR(100) NULL,
        LAST_BUILD VARCHAR(100) NULL,
        LAST_BUILD_STATUS VARCHAR(100) NULL,
        LAST_BUILD_TIME TIMESTAMP NULL,
        REG_CONTENT VARCHAR(1000),
        FOREIGN KEY(REPOSITORY_ID) REFERENCES AF_REPOSITORY(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
        PRIMARY KEY(ID)
);

CREATE TABLE IF NOT EXISTS AF_DEPLOY (
        ID INTEGER AUTO_INCREMENT,
        REPOSITORY_ID INTEGER NOT NULL,
        LAST_DEPLOY VARCHAR(100) NULL,
        LAST_DEPLOY_STATUS VARCHAR(100) NULL,
        LAST_DEPLOY_TIME TIMESTAMP NULL,
        LAST_DEPLOY_TIME_STR VARCHAR(100) NULL,
        ENVIRONMENT VARCHAR(100) NULL,
        REG_CONTENT VARCHAR(1000),
        FOREIGN KEY(REPOSITORY_ID) REFERENCES AF_REPOSITORY(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
        PRIMARY KEY(ID)
);


INSERT INTO AF_VERSION(APPLICATION_ID,VERSION_NAME,REG_CONTENT) 
SELECT APP.ID,R.REG_NAME,C.REG_CONTENT_DATA FROM dbGovernanceCloud.REG_CONTENT C, dbGovernanceCloud.REG_RESOURCE R,dbGovernanceCloud.REG_PATH RP,AF_APPLICATION APP WHERE C.REG_CONTENT_ID = R.REG_CONTENT_ID AND C.REG_TENANT_ID = R.REG_TENANT_ID AND R.REG_MEDIA_TYPE = 'application/vnd.wso2-appversion+xml' AND R.REG_NAME IS NOT NULL AND RP.REG_PATH_ID=R.REG_PATH_ID AND APP.APPLICATION_KEY=RP.REG_PATH_VALUE AND APP.TENANT_ID=C.REG_TENANT_ID;

UPDATE AF_VERSION
SET PROMOTE_STATUS = SUBSTRING(REG_CONTENT,INSTR(REG_CONTENT,'<PromoteStatus>') + CHAR_LENGTH('<PromoteStatus>'))
WHERE REG_CONTENT LIKE '%<PromoteStatus>%' ;

UPDATE AF_VERSION
SET PROMOTE_STATUS = REPLACE(PROMOTE_STATUS,SUBSTRING(PROMOTE_STATUS,INSTR(PROMOTE_STATUS,'</PromoteStatus>')),'')
WHERE PROMOTE_STATUS IS NOT NULL;

-- DONE with AF_VERSION

INSERT INTO AF_REPOSITORY(VERSION_ID,REG_CONTENT)
SELECT VERSION.ID,REG_CONTENT FROM AF_VERSION VERSION;

INSERT INTO AF_REPOSITORY(VERSION_ID,USER_ID,REG_CONTENT)
SELECT VERSION.ID, SUBSTRING(RP.REG_PATH_VALUE,CHAR_LENGTH(SUBSTRING_INDEX(RP.REG_PATH_VALUE, '/', 6))+2),C.REG_CONTENT_DATA FROM dbGovernanceCloud.REG_CONTENT C, dbGovernanceCloud.REG_RESOURCE R,dbGovernanceCloud.REG_PATH RP,AF_APPLICATION APP,AF_VERSION VERSION WHERE C.REG_CONTENT_ID = R.REG_CONTENT_ID AND C.REG_TENANT_ID = R.REG_TENANT_ID AND R.REG_MEDIA_TYPE = 'application/vnd.wso2-repouser+xml' AND R.REG_NAME IS NOT NULL AND RP.REG_PATH_ID=R.REG_PATH_ID AND APP.APPLICATION_KEY=SUBSTRING_INDEX(RP.REG_PATH_VALUE, '/', 6) AND APP.TENANT_ID=C.REG_TENANT_ID AND APP.ID=VERSION.APPLICATION_ID AND VERSION.VERSION_NAME=R.REG_NAME;

UPDATE AF_REPOSITORY
SET REPOSITORY_IS_FORK=1
WHERE USER_ID IS NOT NULL;

-- DONE with AF_REPOSITORY
 
INSERT INTO AF_BUILD(REPOSITORY_ID,REG_CONTENT)
SELECT ID,REG_CONTENT FROM AF_REPOSITORY;

-- Create Deploy holder per Stage

INSERT INTO AF_DEPLOY(REPOSITORY_ID,REG_CONTENT,ENVIRONMENT)
SELECT ID,REG_CONTENT,'Development' FROM AF_REPOSITORY;

INSERT INTO AF_DEPLOY(REPOSITORY_ID,REG_CONTENT,ENVIRONMENT)
SELECT ID,REG_CONTENT,'Testing' FROM AF_REPOSITORY;

INSERT INTO AF_DEPLOY(REPOSITORY_ID,REG_CONTENT,ENVIRONMENT)
SELECT ID,REG_CONTENT,'Production' FROM AF_REPOSITORY;

 
UPDATE AF_BUILD
SET LAST_BUILD = SUBSTRING(REG_CONTENT,INSTR(REG_CONTENT,'<LastBuildStatus>') + CHAR_LENGTH('<LastBuildStatus>'))
WHERE REG_CONTENT LIKE '%<LastBuildStatus>%' ;

UPDATE AF_BUILD
SET LAST_BUILD = REPLACE(LAST_BUILD,SUBSTRING(LAST_BUILD,INSTR(LAST_BUILD,'</LastBuildStatus>')),'')
WHERE LAST_BUILD IS NOT NULL;

UPDATE AF_BUILD
SET LAST_BUILD_STATUS = SUBSTRING_INDEX(LAST_BUILD, ' ', -1)
WHERE LAST_BUILD IS NOT NULL ;

UPDATE AF_BUILD
SET LAST_BUILD = SUBSTRING_INDEX(SUBSTRING_INDEX(LAST_BUILD, ' ', 2),' ',-1)
WHERE LAST_BUILD IS NOT NULL;

UPDATE AF_BUILD
SET LAST_BUILD_TIME = NOW()
WHERE LAST_BUILD IS NOT NULL ;

UPDATE AF_BUILD
SET CURRENT_BUILD = SUBSTRING(REG_CONTENT,INSTR(REG_CONTENT,'<CurrentBuildStatus>') + CHAR_LENGTH('<CurrentBuildStatus>'))
WHERE REG_CONTENT LIKE '%<CurrentBuildStatus>%' ;

UPDATE AF_BUILD
SET CURRENT_BUILD = REPLACE(CURRENT_BUILD,SUBSTRING(CURRENT_BUILD,INSTR(CURRENT_BUILD,'</CurrentBuildStatus>')),'')
WHERE CURRENT_BUILD IS NOT NULL;

-- DONE with AF_BUILD

-- UPDATE Dev --
UPDATE AF_DEPLOY
SET LAST_DEPLOY_STATUS = SUBSTRING(REG_CONTENT,INSTR(REG_CONTENT,'<DeploymentStatus.Development>') + CHAR_LENGTH('<DeploymentStatus.Development>'))
WHERE REG_CONTENT LIKE '%<DeploymentStatus.Development>%' AND ENVIRONMENT='Development' ;

UPDATE AF_DEPLOY
SET LAST_DEPLOY_STATUS = REPLACE(LAST_DEPLOY_STATUS,SUBSTRING(LAST_DEPLOY_STATUS,INSTR(LAST_DEPLOY_STATUS,'</DeploymentStatus.Development')),'')
WHERE LAST_DEPLOY_STATUS IS NOT NULL;

-- UPDATE Test --
UPDATE AF_DEPLOY
SET LAST_DEPLOY_STATUS = SUBSTRING(REG_CONTENT,INSTR(REG_CONTENT,'<DeploymentStatus.Testing>') + CHAR_LENGTH('<DeploymentStatus.Testing>'))
WHERE REG_CONTENT LIKE '%<DeploymentStatus.Testing>%' AND ENVIRONMENT='Testing' ;

UPDATE AF_DEPLOY
SET LAST_DEPLOY_STATUS = REPLACE(LAST_DEPLOY_STATUS,SUBSTRING(LAST_DEPLOY_STATUS,INSTR(LAST_DEPLOY_STATUS,'</DeploymentStatus.Testing')),'')
WHERE LAST_DEPLOY_STATUS IS NOT NULL;

-- UPDATE Prod --
UPDATE AF_DEPLOY
SET LAST_DEPLOY_STATUS = SUBSTRING(REG_CONTENT,INSTR(REG_CONTENT,'<DeploymentStatus.Production>') + CHAR_LENGTH('<DeploymentStatus.Production>'))
WHERE REG_CONTENT LIKE '%<DeploymentStatus.Production>%' AND ENVIRONMENT='Production' ;

UPDATE AF_DEPLOY
SET LAST_DEPLOY_STATUS = REPLACE(LAST_DEPLOY_STATUS,SUBSTRING(LAST_DEPLOY_STATUS,INSTR(LAST_DEPLOY_STATUS,'</DeploymentStatus.Production')),'')
WHERE LAST_DEPLOY_STATUS IS NOT NULL;


UPDATE AF_DEPLOY
SET LAST_DEPLOY_STATUS = SUBSTRING(SUBSTRING_INDEX(LAST_DEPLOY_STATUS,'>',-1),1)
WHERE LAST_DEPLOY_STATUS IS NOT NULL;

UPDATE AF_DEPLOY
SET LAST_DEPLOY_TIME_STR = SUBSTRING(REG_CONTENT,INSTR(REG_CONTENT,'<LastSuccessDeployedTime>') + CHAR_LENGTH('<LastSuccessDeployedTime>'))
WHERE REG_CONTENT LIKE '%<LastSuccessDeployedTime>%' AND LAST_DEPLOY_STATUS='Success';

-- Type of LAST_DEPLOY_TIME is TIMESTAME but in RXT it is millisecond from epoch.Milli second in String ->INT->TIMESTAMP

UPDATE AF_DEPLOY
SET LAST_DEPLOY_TIME_STR = REPLACE(LAST_DEPLOY_TIME_STR,SUBSTRING(LAST_DEPLOY_TIME_STR,INSTR(LAST_DEPLOY_TIME_STR,'<LastSuccessDeployedTime>')),'')
 WHERE LAST_DEPLOY_TIME_STR IS NOT NULL;
 
UPDATE AF_DEPLOY
SET LAST_DEPLOY_TIME = FROM_UNIXTIME(CAST(LAST_DEPLOY_TIME_STR AS UNSIGNED)/1000)
WHERE LAST_DEPLOY_TIME_STR IS NOT NULL;

ALTER TABLE AF_DEPLOY DROP LAST_DEPLOY_TIME_STR;

UPDATE AF_DEPLOY
SET LAST_DEPLOY = SUBSTRING(REG_CONTENT,INSTR(REG_CONTENT,'<lastdeployedid>') + CHAR_LENGTH('<lastdeployedid>'))
WHERE REG_CONTENT LIKE '%<lastdeployedid>%';

UPDATE AF_DEPLOY
SET LAST_DEPLOY = REPLACE(LAST_DEPLOY,SUBSTRING(LAST_DEPLOY,INSTR(LAST_DEPLOY,'</lastdeployedid>')),'')
WHERE LAST_DEPLOY IS NOT NULL;

-- DONE with AF_DEPLOY

UPDATE AF_APPLICATION
SET APPLICATION_KEY = SUBSTRING(APPLICATION_KEY, CHAR_LENGTH('/_system/governance/repository/applications/')+1);

CREATE TABLE IF NOT EXISTS AF_RESOURCE (
        ID INTEGER AUTO_INCREMENT,
        APPLICATION_ID INTEGER NOT NULL,
        RESOURCE_TYPE VARCHAR(100) NOT NULL,
        RESOURCE_NAME VARCHAR(100) NOT NULL,
        ENVIRONMENT VARCHAR(100) NOT NULL,
        FOREIGN KEY(APPLICATION_ID) REFERENCES AF_APPLICATION(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
        PRIMARY KEY(ID)
);
INSERT INTO AF_RESOURCE(APPLICATION_ID,RESOURCE_TYPE,RESOURCE_NAME,ENVIRONMENT)
SELECT APP.ID,'DATABASE',SUBSTRING_INDEX(SUBSTRING_INDEX(RP.REG_PATH_VALUE, '/', -2),'/',-1),SUBSTRING_INDEX(SUBSTRING_INDEX(RP.REG_PATH_VALUE, '/rss/', -1),'/database/',1) FROM dbGovernanceCloud.REG_CONTENT C, dbGovernanceCloud.REG_RESOURCE R,dbGovernanceCloud.REG_PATH RP,AF_APPLICATION APP WHERE C.REG_CONTENT_ID = R.REG_CONTENT_ID AND C.REG_TENANT_ID = R.REG_TENANT_ID AND R.REG_MEDIA_TYPE = 'application/vnd.wso2-database+xml' AND R.REG_NAME IS NOT NULL AND RP.REG_PATH_ID=R.REG_PATH_ID AND APP.APPLICATION_KEY=SUBSTRING_INDEX(SUBSTRING_INDEX(RP.REG_PATH_VALUE, '/', -2),'/',1) AND APP.TENANT_ID=C.REG_TENANT_ID;

INSERT INTO AF_RESOURCE(APPLICATION_ID,RESOURCE_TYPE,RESOURCE_NAME,ENVIRONMENT)
SELECT APP.ID,'DATABASE_USER',SUBSTRING_INDEX(SUBSTRING_INDEX(RP.REG_PATH_VALUE, '/', -2),'/',-1),SUBSTRING_INDEX(SUBSTRING_INDEX(RP.REG_PATH_VALUE, '/rss/', -1),'/users/',1) FROM dbGovernanceCloud.REG_CONTENT C, dbGovernanceCloud.REG_RESOURCE R,dbGovernanceCloud.REG_PATH RP,AF_APPLICATION APP WHERE C.REG_CONTENT_ID = R.REG_CONTENT_ID AND C.REG_TENANT_ID = R.REG_TENANT_ID AND R.REG_MEDIA_TYPE = 'application/vnd.wso2-user+xml' AND R.REG_NAME IS NOT NULL AND RP.REG_PATH_ID=R.REG_PATH_ID AND APP.APPLICATION_KEY=SUBSTRING_INDEX(SUBSTRING_INDEX(RP.REG_PATH_VALUE, '/', -2),'/',1) AND APP.TENANT_ID=C.REG_TENANT_ID;

INSERT INTO AF_RESOURCE(APPLICATION_ID,RESOURCE_TYPE,RESOURCE_NAME,ENVIRONMENT)
SELECT APP.ID,'DATABASE_TEMPLATE',SUBSTRING_INDEX(SUBSTRING_INDEX(RP.REG_PATH_VALUE, '/', -2),'/',-1),SUBSTRING_INDEX(SUBSTRING_INDEX(RP.REG_PATH_VALUE, '/rss/', -1),'/template/',1) FROM dbGovernanceCloud.REG_CONTENT C, dbGovernanceCloud.REG_RESOURCE R,dbGovernanceCloud.REG_PATH RP,AF_APPLICATION APP WHERE C.REG_CONTENT_ID = R.REG_CONTENT_ID AND C.REG_TENANT_ID = R.REG_TENANT_ID AND R.REG_MEDIA_TYPE = 'application/vnd.wso2-template+xml' AND R.REG_NAME IS NOT NULL AND RP.REG_PATH_ID=R.REG_PATH_ID AND APP.APPLICATION_KEY=SUBSTRING_INDEX(SUBSTRING_INDEX(RP.REG_PATH_VALUE, '/', -2),'/',1) AND APP.TENANT_ID=C.REG_TENANT_ID;

-- DONE with AF_RESOURCE
-- Remove helper columns
ALTER TABLE AF_APPLICATION DROP REG_CONTENT;
ALTER TABLE AF_VERSION DROP REG_CONTENT;
ALTER TABLE AF_REPOSITORY DROP REG_CONTENT;
ALTER TABLE AF_BUILD DROP REG_CONTENT;
ALTER TABLE AF_DEPLOY DROP REG_CONTENT;

-- DONE
