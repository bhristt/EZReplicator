--// written by bhristt (march 13 2022)
--// updated: march 17 2022
--// settings module for the replicator and subscription classes


local SETTINGS = {
	
	--// subscription settings
	SUBSCRIPTION_WAIT_INTERVAL = 1,
	SUBSCRIPTION_MAX_WAIT_TIME = 5,
	
	--// initial replication setup
	MAX_SERVER_DATA_REQUEST_RETRIES = 4,
	DATA_RETRY_WAIT_TIME = 1,
	
}


return SETTINGS