/*===========================================================================
     Added to RK base RMIS product as  03/25/2013
   ===========================================================================*/
    
public class VFFileUpload { 
   
    public Id recId {get;set;}
    public VFFileUpload(ApexPages.StandardController ctlr) {recId = ctlr.getRecord().Id;}
    
    public string fileName1{get;set;}
    public string fileAlias1{get;set;}
    public string fileKeyword1{get;set;}
    public Blob fileBody1  {get;set;}
    
    public string fileAlias2{get;set;}
    public string fileName2{get;set;}
    public string fileKeyword2{get;set;}
    public Blob fileBody2  {get;set;}
    
    public string fileName3{get;set;}
    public string fileAlias3{get;set;}
    public string fileKeyword3{get;set;}
    public Blob fileBody3  {get;set;}
    
    public string fileName4{get;set;}
    public string fileAlias4{get;set;}
    public string fileKeyword4{get;set;}
    public Blob fileBody4  {get;set;}
    
    public string fileName5{get;set;}
    public string fileAlias5{get;set;}
    public string fileKeyword5{get;set;}
    public Blob fileBody5  {get;set;}
    
   
    
    public string subjectheader{get;set;}
    
    public PageReference UploadFile() {
        PageReference pr;
         Id folderId = null;
         Id docId1 = null;  Id docId2 = null;  Id docId3 = null;  Id docId4 = null;  Id docId5 = null;
        
         
        
         String sysUrl = 'https://na7.salesforce.com/';
         
        //Find the folder Id where the documents will be stored
                List<Folder> folders = new List<Folder>([Select Id From Folder Where Name = : 'Attachments'  Limit 1]);
                for (Folder fId : folders) folderId = fId.Id;      
        
          
        if(fileBody1 != null && fileName1 != null)    {
            Document d1 = new Document();
            d1.Name = filename1;
            d1.Description = ' This document is referenced in ' +  sysUrl + String.valueOf(recId);
            d1.Body = fileBody1;
            d1.Keywords = fileAlias1 + ' ' + filename1 + ' ' + fileKeyword1;
            d1.FolderId = folderId;
            insert d1;
            docId1 = d1.Id;
            }
         
        if(fileBody2 != null && fileName2 != null)    {
            Document d2 = new Document();
            d2.Name = filename2;
            d2.Description = ' This document is referenced in ' +  sysUrl + String.valueOf(recId);
            d2.Body = fileBody2;
            d2.Keywords = fileAlias2 + ' ' + filename2 + ' ' + fileKeyword2;
            d2.FolderId = folderId;
            insert d2;
            docId2 = d2.Id;
            }
        if(fileBody3 != null && fileName3 != null)    {
            Document d3 = new Document();
            d3.Name = filename3;
            d3.Description = ' This document is referenced in ' +  sysUrl + String.valueOf(recId);
            d3.Body = fileBody3;
            d3.Keywords = fileAlias3 + ' ' + filename3 + ' ' + fileKeyword3;
            d3.FolderId = folderId;
            insert d3;
            docId3 = d3.Id;
            }
         if(fileBody4 != null && fileName4 != null)    {
            Document d4 = new Document();
            d4.Name = filename4;
            d4.Description = ' This document is referenced in ' +  sysUrl + String.valueOf(recId);
            d4.Body = fileBody4;
            d4.Keywords = fileAlias4 + ' ' + filename4 + ' ' + fileKeyword4;
            d4.FolderId = folderId;
            insert d4;
            docId4 = d4.Id;
            }
         if(fileBody5 != null && fileName5 != null)    {
            Document d5 = new Document();
            d5.Name = filename5;
            d5.Description = ' This document is referenced in ' +  sysUrl + String.valueOf(recId);
            d5.Body = fileBody5;
            d5.Keywords = fileAlias5 + ' ' + filename5 + ' ' + fileKeyword5;
            d5.FolderId = folderId;
            insert d5;
            docId5 = d5.Id;
            }
        
          
            
        Task t =  [Select Id 
                   From Task Where Id=:recId Limit 1 
                   FOR UPDATE];
                   
        if (docId1 != null){
            t.DocumentID_1__c = docId1;
            if(fileAlias1 != '') {t.Document_Name_1__c = fileAlias1;} else {t.Document_Name_1__c = filename1;}
            }
        
        if (docId2 != null){
            t.DocumentID_2__c = docId2;
            if(fileAlias2 != '') {t.Document_Name_2__c = fileAlias2;} else {t.Document_Name_2__c = filename2;}
            }
        if (docId3 != null){
            t.DocumentID_3__c = docId3;
            if(fileAlias3 != '') {t.Document_Name_3__c = fileAlias3;} else {t.Document_Name_3__c = filename3;}
            }
        if (docId4 != null){
            t.DocumentID_4__c = docId4;
            if(fileAlias4 != '') {t.Document_Name_4__c = fileAlias4;} else {t.Document_Name_4__c = filename4;}
            }
        if (docId5 != null){
            t.DocumentID_5__c = docId5;
            if(fileAlias5 != '') {t.Document_Name_5__c = fileAlias5;} else {t.Document_Name_5__c = filename5;}
            }
       
            
        Update t;
        
        pr = new PageReference('/' + recId);
        pr.setRedirect(true);
        return pr;
        return null;
    }
        
    public PageReference UploadFileClaim() {
        PageReference pr;
         Id folderId = null;
         Task[] newTask = new Task[0]; 
         Id docId1 = null; Id docId2 = null; Id docId3 = null; Id docId4 = null; Id docId5 = null;
       
          
         String tName1 = null; String tName2 = null; String tName3 = null; String tName4 = null; String tName5 = null;
                
         String sysUrl = 'https://na7.salesforce.com/';
         
         String tSubject = null;
         
        //Find the folder Id where the documents will be stored
                List<Folder> folders = new List<Folder>([Select Id From Folder Where Name = : 'Attachments'  Limit 1]);
                for (Folder fId : folders) folderId = fId.Id;      
        
          
        if(fileBody1 != null && fileName1 != null)    {
            Document d1 = new Document();
            d1.Name = filename1;
            d1.Description = ' This document is referenced in ' +  sysUrl + String.valueOf(recId);
            d1.Body = fileBody1;
            d1.Keywords = fileAlias1 + ' ' + filename1 + ' ' + fileKeyword1;
            d1.FolderId = folderId;
            insert d1;
            docId1 = d1.Id;
            }
         
        if(fileBody2 != null && fileName2 != null)    {
            Document d2 = new Document();
            d2.Name = filename2;
            d2.Description = ' This document is referenced in ' +  sysUrl + String.valueOf(recId);
            d2.Body = fileBody2;
            d2.Keywords = fileAlias2 + ' ' + filename2 + ' ' + fileKeyword2;
            d2.FolderId = folderId;
            insert d2;
            docId2 = d2.Id;
            }
        if(fileBody3 != null && fileName3 != null)    {
            Document d3 = new Document();
            d3.Name = filename3;
            d3.Description = ' This document is referenced in ' +  sysUrl + String.valueOf(recId);
            d3.Body = fileBody3;
            d3.Keywords = fileAlias3 + ' ' + filename3 + ' ' + fileKeyword3;
            d3.FolderId = folderId;
            insert d3;
            docId3 = d3.Id;
            }
         if(fileBody4 != null && fileName4 != null)    {
            Document d4 = new Document();
            d4.Name = filename4;
            d4.Description = ' This document is referenced in ' +  sysUrl + String.valueOf(recId);
            d4.Body = fileBody4;
            d4.Keywords = fileAlias4 + ' ' + filename4 + ' ' + fileKeyword4;
            d4.FolderId = folderId;
            insert d4;
            docId4 = d4.Id;
            }
         if(fileBody5 != null && fileName5 != null)    {
            Document d5 = new Document();
            d5.Name = filename5;
            d5.Description = ' This document is referenced in ' +  sysUrl + String.valueOf(recId);
            d5.Body = fileBody5;
            d5.Keywords = fileAlias5 + ' ' + filename5 + ' ' + fileKeyword5;
            d5.FolderId = folderId;
            insert d5;
            docId5 = d5.Id;
            }
        
            
            if(fileAlias1 != '') {tName1 = fileAlias1;} else {tName1 = filename1;}
            if(fileAlias2 != '') {tName2 = fileAlias2;} else {tName2 = filename2;}
            if(fileAlias3 != '') {tName3 = fileAlias3;} else {tName3 = filename3;}
            if(fileAlias4 != '') {tName4 = fileAlias4;} else {tName4 = filename4;}
            if(fileAlias5 != '') {tName5 = fileAlias5;} else {tName5 = filename5;}
           
            
            if(subjectheader != '') {tSubject = subjectheader;} else {tSubject = 'Attachments';}
            
                RecordType rt = [Select r.Id  
                                    From   RecordType r
                                    Where  SobjectType = 'Task' 
                                    and    Name = 'Task' Limit 1];  
               Id recTypeId = rt.Id;
            
                         
               //Create a new 'Completed' Task
                newTask.add( new Task(Description = '',
                                      Priority = 'Normal',
                                      Status = 'Completed',
                                      Note_Type__c = 'File Note',
                                      Subject = tSubject,
                                      WhatId  = recId,
                                      OwnerId = UserInfo.getUserId(),
                                     
                                      RecordTypeId = recTypeId,                  
                                      ActivityDate = System.today(),
                                      
                                      From_Email__c = '',
                                      DocumentID_1__c = docId1,
                                      DocumentID_2__c = docId2,
                                      DocumentID_3__c = docId3,
                                      DocumentID_4__c = docId4,
                                      DocumentID_5__c = docId5,
                                     
                                      Document_Name_1__c = tName1, 
                                      Document_Name_2__c = tName2, 
                                      Document_Name_3__c = tName3, 
                                      Document_Name_4__c = tName4, 
                                      Document_Name_5__c = tName5
                                      ));        
                insert newTask;
                
        
        pr = new PageReference('/' + recId);
        pr.setRedirect(true);
        return pr;
        
        return null;
    }
    
    static testMethod void testVFFileUpload() {
        Task t = new Task();
        insert t;
        ApexPages.StandardController sc = new ApexPages.Standardcontroller(t);
        PageReference pageRef = new PageReference('/apex/Attachments_for_Tasks');
        
        VFFileUpload vff = new VFFileUpload(sc);
            
        vff.fileName1 = 'FileNameString';
        vff.fileAlias1 = 'FileAliasString';
        vff.fileKeyword1 = 'FileKeyWord';
        vff.fileBody1 = Encodingutil.base64Decode('Body Blob Test');
        
        vff.fileName2 = 'FileNameString';
        vff.fileAlias2 = 'FileAliasString';
        vff.fileKeyword2 = 'FileKeyWord';
        vff.fileBody2 = Encodingutil.base64Decode('Body Blob Test');
                
        vff.fileName3 = 'FileNameString';
        vff.fileAlias3 = 'FileAliasString';
        vff.fileKeyword3 = 'FileKeyWord';
        vff.fileBody3 = Encodingutil.base64Decode('Body Blob Test');        
        
        vff.fileName4 = 'FileNameString';
        vff.fileAlias4 = 'FileAliasString';
        vff.fileKeyword4 = 'FileKeyWord';
        vff.fileBody4 = Encodingutil.base64Decode('Body Blob Test');        
    
        vff.fileName5 = 'FileNameString';
        vff.fileAlias5 = 'FileAliasString';
        vff.fileKeyword5 = 'FileKeyWord';
        vff.fileBody5 = Encodingutil.base64Decode('Body Blob Test');
    
       
                                                
        vff.UploadFile();
            
         Claim__c c = new Claim__c (Name = 'Test Claim', Status__c = 'Open',  
                                   Date_of_Loss__c = System.today() );
        insert c;
        vff.recId = c.Id; 
        
    
        vff.UploadFileClaim();
        
    }
    
    
}