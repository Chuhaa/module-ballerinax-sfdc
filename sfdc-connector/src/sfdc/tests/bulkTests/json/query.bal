// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/log;
import ballerina/test;

@test:Config {
    dependsOn: ["updateJson", "insertJsonFromFile"]
}
function queryJson() {
    log:printInfo("bulkClient -> queryJson");
    string batchId = "";

    string queryStr = "SELECT Id, Name FROM Contact WHERE Title='Professor Grade 03'";

    //create job
    error|BulkJob queryJob = bulkClient->creatJob("query", "Contact", "JSON");

    if (queryJob is BulkJob) {
        //add query string
        error|BatchInfo batch = queryJob->addBatch(queryStr);
        if (batch is BatchInfo) {
            test:assertTrue(batch.id.length() > 0, msg = "Could not add batch.");
            batchId = batch.id;
        } else {
            test:assertFail(msg = batch.detail()?.message.toString());
        }

        //get job info
        error|JobInfo jobInfo = bulkClient->getJobInfo(queryJob);
        if (jobInfo is JobInfo) {
            test:assertTrue(jobInfo.id.length() > 0, msg = "Getting job info failed.");
        } else {
            test:assertFail(msg = jobInfo.detail()?.message.toString());
        }

        //get batch info
        error|BatchInfo batchInfo = queryJob->getBatchInfo(batchId);
        if (batchInfo is BatchInfo) {
            test:assertTrue(batchInfo.id == batchId, msg = "Getting batch info failed.");
        } else {
            test:assertFail(msg = batchInfo.detail()?.message.toString());
        }

        //get all batches
        error|BatchInfo[] batchInfoList = queryJob->getAllBatches();
        if (batchInfoList is BatchInfo[]) {
            test:assertTrue(batchInfoList.length() == 1, msg = "Getting all batches info failed.");
        } else {
            test:assertFail(msg = batchInfoList.detail()?.message.toString());
        }

        //get batch request
        var batchRequest = queryJob->getBatchRequest(batchId);
        if (batchRequest is string) {
            test:assertTrue(batchRequest.startsWith("SELECT"), msg = "Retrieving batch request failed.");
        } else if (batchRequest is error) {
            test:assertFail(msg = batchRequest.detail()?.message.toString());
        } else {
            test:assertFail(msg = "Invalid Batch Request!");
        }

        //get batch result
        var batchResult = queryJob->getBatchResult(batchId);
        if (batchResult is json) {
            json[]|error batchResultArr = <json[]>batchResult;
            if (batchResultArr is json[]) {
                jsonQueryResult = <@untainted>batchResultArr;
                test:assertTrue(batchResultArr.length() == 5, msg = "Retrieving batch result failed.");
            } else {
                test:assertFail(msg = batchResultArr.toString());
            }
        } else if (batchResult is error) {
            test:assertFail(msg = batchResult.detail()?.message.toString());
        } else {
            test:assertFail("Invalid Batch Result!");
        }

        //close job
        error|JobInfo closedJob = bulkClient->closeJob(queryJob);
        if (closedJob is JobInfo) {
            test:assertTrue(closedJob.state == "Closed", msg = "Closing job failed.");
        } else {
            test:assertFail(msg = closedJob.detail()?.message.toString());
        }
    } else {
        test:assertFail(msg = queryJob.detail()?.message.toString());
    }
}
