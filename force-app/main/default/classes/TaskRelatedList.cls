/*===========================================================================
     Added to RK base RMIS product as  10/31/2104
     Bobby Carlisle 07/16
      ===========================================================================*/
  




public with sharing class TaskRelatedList {
    
    // public TaskRelatedList() {}

 //    Id claimId = System.currentPageReference().getParameters().get('id');
 //    public List<OpenActivity> task = new OpenActivity[]{};

  
   
    
 //     public TaskRelatedList(ApexPages.StandardController controller) {
       
 //       //task = [SELECT ActivityDate FROM OpenActivities where ParentId = :System.currentPageReference().getParameters().get('id')];
 //       task = [SELECT (Select ActivityDate, Description FROM OpenActivities where Id = :System.currentPageReference().getParameters().get('id') ) From Claim__c Where Id=:claimId].OpenActivities;
 //       //Claim__c a = [select id, Name from Claim__c where id = :System.currentPageReference().getParameters().get('id')];
 //    }
    
 //    public List<OpenActivity> getClaimTask() {
 //        return task;
 //    }
    public Id claimId { get; set; }
    public List<Task> activeClaimTasks { get; set; }
    public List<Task> inactiveClaimTasks { get; set; }

    public TaskRelatedList() {
        this.claimId = System.currentPageReference().getParameters().get('id');
        this.queryAndPartitionTasks();
    }

    public TaskRelatedList(ApexPages.StandardController controller) {
        this.claimId = System.currentPageReference().getParameters().get('id');
        this.queryAndPartitionTasks();
    }

    public void queryAndPartitionTasks() {
        this.activeClaimTasks = new List<Task>();
        this.inactiveClaimTasks = new List<Task>();

        for (Task task : [ SELECT Owner.Name, Subject, WhatId, Description, Status, LastModifiedDate FROM Task WHERE WhatId = :this.claimId ]) {
            if (task.Status != 'Completed') {
                this.activeClaimTasks.add(task);
            } else {
                this.inactiveClaimTasks.add(task);
            }
        }
    }
}