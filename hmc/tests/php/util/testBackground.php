<?php

include_once '../util/Logger.php';
include_once '../conf/Config.inc';
include_once "../util/lock.php";
include_once '../db/HMCDBAccessor.php';

include_once "HMCTxnUtils.php";
include_once "../orchestrator/Service.php";
include_once "../orchestrator/ServiceComponent.php";

$GLOBALS["HMC_LOG_LEVEL"] = HMCLogger::DEBUG;
$GLOBALS["HMC_LOG_FILE"] = "./hmc.log";
$GLOBALS["BACKGROUND_EXECUTOR_PATH"] = "./BackgroundExecutor.php";

system("rm -rf /tmp/foo");
system("rm -rf /tmp/foo1");
system("rm -rf ./test.db");
system("rm -rf ./hmc.log");

assert_options(ASSERT_BAIL, 1);

system("sqlite3 ./test.db < ../../../db/schema.dump");
$dbPath = "./test.db";
$dbHandle = new HMCDBAccessor($dbPath);

$clusterName = "TestCluster";
$command = "./test.sh";
$args = "";
$logFile = "/tmp/foo1";

$result = HMCTxnUtils::createNewTransaction($dbHandle, $clusterName, "status");
assert($result !== FALSE);

$txnId = $result;
print ("TXN ID: $txnId\n");
$startTime = time(0);
print "Start: $startTime\n";
$result = HMCTxnUtils::execBackgroundProcess($dbHandle, $clusterName, $txnId,
    $command, $args, $logFile);
assert($result !== FALSE);
$endTime = time(0);

print "End: $endTime\n";
print "Time taken: ".($endTime - $startTime)."\n";

assert (($endTime - $startTime) < 3);

print("PID: $result\n");

$result = HMCTxnUtils::createNewTransaction($dbHandle, $clusterName);
assert($result !== FALSE);

$txnId = $result;
print ("TXN ID: $txnId\n");
$startTime = time(0);
print "Start: $startTime\n";
$result = HMCTxnUtils::execBackgroundProcess($dbHandle, $clusterName, $txnId,
    $command, $args, $logFile);
assert($result !== FALSE);
$endTime = time(0);

print "End: $endTime\n";
print "Time taken: ".($endTime - $startTime)."\n";

assert (($endTime - $startTime) < 3);

print("PID: $result\n");

?>
