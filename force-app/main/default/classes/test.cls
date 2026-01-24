public class NS_GeneralContactEditFormController {
    
    @AuraEnabled
    public static List <Contact> fetchDuplicateContact(String emailAdd,id recId) {
        
        List<Contact> conList =new List<Contact>();
        
        if(!String.isBlank(emailAdd)){
            conList = [Select id,name,AccountId,Account_Name_Formula__c,NS_PreferredName__c,Email,MailingAddress,
                       MobilePhone,Phone,NS_ContactRole__c from Contact where Email=: emailAdd AND id !=: recId];
        }        
        return conList;
        
    }
    
    @AuraEnabled
    public static List <Contact> fetchDuplicatePhoneNameContact(String firstName,String lastName,String accountId,String workPhone,String mobilePhone,String recId) {
        string cols;
        string condition;
        
        cols = 'id,name,AccountId,Account_Name_Formula__c,NS_PreferredName__c,Email,MailingAddress,MobilePhone,Phone,NS_ContactRole__c';
        
         
        if(!String.isBlank(workPhone) && !String.isBlank(mobilePhone)){
             condition = 'LastName=:lastName AND(MobilePhone =:mobilePhone OR Phone =:workPhone OR (FirstName =:firstName AND AccountId =:accountId))';
        }
        else if(!String.isBlank(workPhone) && String.isBlank(mobilePhone)){
           condition = 'LastName=:lastName AND (Phone =:workPhone OR (FirstName =:firstName AND AccountId =:accountId))';
        }
        else if(String.isBlank(workPhone) && !String.isBlank(mobilePhone)){
            condition = 'LastName=:lastName AND (MobilePhone =:mobilePhone OR (FirstName =:firstName AND AccountId =:accountId))';
        }
        
        else if(String.isBlank(workPhone) && String.isBlank(mobilePhone)){
            condition = 'LastName=:lastName AND FirstName =:firstName AND AccountId =:accountId';
        }
        
        
        //string query = 'select '+cols+' from Contact where '+condition+' AND id != \''+recId+'\'';
        
        //system.debug('[+]Query : '+query);
        //system.debug( Database.query(query));
        string query = 'select '+cols+' from Contact where '+condition+' AND id !=: recId';
        
        
        system.debug( Database.query(String.escapeSingleQuotes(query)));
        List<Contact> conList = Database.query(String.escapeSingleQuotes(query));
        
        return conList;
    }
    @AuraEnabled
    public static string accountRecordtypeCheck(Id accountId){
        return [select id,RecordType.DeveloperName from Account where id =: accountId Limit 01].RecordType.DeveloperName;
    }
    
    // Method to return Logged In User Profile   
    @AuraEnabled
    public static String loggedInUserProfile(){
        Id profileId=userinfo.getProfileId();
        String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
        system.debug('ProfileName'+profileName);
        return profileName; 
    }
    
    //Method to return details of current contact
    @AuraEnabled
    public static List<Contact> fetchCurrentRecordDetails(id recId)
    {
        List<Contact> con = [select id,FirstName,LastName,Email,Phone,MobilePhone,OtherPhone,HomePhone,NS_Mastered_Contact_Indicator__c,NS_PreferredName__c,AccountId from contact where id =: recId Limit 1];
        return con;
    }
    
    //Experimental Method
    @AuraEnabled
    public static string accNamePopulator(id accId)
    {
        return [select Name from Account where id =: accId Limit 01].Name; 
    }
    
    //Method to send changed details to MDM Server(Currently Generates XML)
    @AuraEnabled 
    public static String sendConToMDMApexController(id recId)
    {
        //String todayDate = datetime.now().formatGMT('yyyy-MM-dd\' \'HH:mm:ss.SSS'); //2020-04-21 07:25:35.799
        ////String reqId =  datetime.now().formatGMT('yyyyMMddSSSS');//202004250485
        User currentUser = [SELECT Name,FederationIdentifier FROM User where id =: userInfo.getUserId() Limit 01];
        contact c = [select id,FirstName,LastName,NSSource_System__c,Phone,Email,MobilePhone,NS_Work_Phone_Ext__c,NS_PreferredName__c,NS_Contact_MDM_EID__c,NS_RACF_ID__c,NS_Mastered_Contact_Indicator__c,NS_AccessNS_Authorization_Status__c,Notification_SMS_Enabled__c,Notification_Email_Enabled__c from contact where id =: recId Limit 01];
        
       String ENDPOINT_KEY ='ContactMDMEndpoint';
       String endpointMDM;                                     
       Map<String,NS_Integration_Endpoints__c> endpoints = NS_Integration_Endpoints__c.getAll();  
        if(endpoints.containsKey(ENDPOINT_KEY)){
            endpointMDM = endpoints.get(ENDPOINT_KEY).Endpoint_URL__c;
        }
        String resultCode;
        String masteredIndicator;
        String sourceSystem;
        Datetime todaysdt = System.now();
        String date1 = String.valueOf(todaysdt.date());
        String time1 = String.valueOf(todaysdt.time());
        String year = date1.substring(0,4);
        String month = date1.substring(5,7);
        String day = date1.substring(8,10);
        String hour1 = time1.substring(0,2);
        String min1 = time1.substring(3,5);
        String sec1 = time1.substring(6,8);
        String reqId = year+month+day+hour1+min1+sec1;
        String body;
        
        String workPhone = c.Phone;
        String mobilePhone = c.MobilePhone;
        
        string wPhnAreaCode;
        string wPhone;
        
        string mPhnAreaCode;
        string mPhone;
        
        if(!String.isBlank(workPhone) && workPhone.startsWith('1')){
            wPhnAreaCode = workPhone.substring(1,4);
            wPhone = workPhone.substring(4);
        }
        else if(!String.isBlank(workPhone)){
            wPhnAreaCode = workPhone.substring(0,3);
            wPhone = workPhone.substring(3);
        }   
        
        if(!String.isBlank(mobilePhone) && mobilePhone.startsWith('1')){
            mPhnAreaCode = mobilePhone.substring(1,4);
            mPhone = mobilePhone.substring(4);
        }
        else if(!String.isBlank(mobilePhone)){
            mPhnAreaCode = mobilePhone.substring(0,3);
            mPhone = mobilePhone.substring(3);
        } 
        
        if(c.NS_Contact_MDM_EID__c != null && !c.NS_Contact_MDM_EID__c.toLowerCase().contains('old')) {
        body='<?xml version="1.0" encoding="UTF-8"?>';
        body+='<TCRMService xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.ibm.com/mdm/schema" xsi:schemaLocation="http://www.ibm.com/mdm/schema MDMDomains.xsd">';
        body+='<RequestControl>';
        body+='<requestID>'+reqId+'</requestID>';
        body+='<DWLControl>';
        body+='<requesterName>'+currentUser.FederationIdentifier+'</requesterName>';
        body+='<requesterLanguage>100</requesterLanguage>';
        body+='</DWLControl>';
        body+='</RequestControl>';
        body+='<TCRMTx>';
        body+='<TCRMTxType>maintainContact</TCRMTxType>';
        body+='<TCRMTxObject>NSContactBObj</TCRMTxObject>';
        body+='<TCRMObject>';
        body+='<NSContactBObj>';
        body+='<ActionIndicator>Update</ActionIndicator>';
        body+='<FirstName>'+c.FirstName+'</FirstName>';
        body+='<LastName>'+c.LastName+'</LastName>';
        //body+='<PreferredName>'+c.NS_PreferredName__c+'</PreferredName>';
        if(String.isBlank(c.NS_PreferredName__c)){
            body+='<PreferredName></PreferredName>';
        }else{
            body+='<PreferredName>'+c.NS_PreferredName__c+'</PreferredName>';
        }
        //body+='<Email>'+c.Email+'</Email>';
        if(!String.isBlank(c.Email)){
            body+='<Email>'+c.Email+'</Email>';
        }
        if(c.Notification_Email_Enabled__c){//Contact.Notification_Email_Enabled__c
            body+='<EmailNotificationIndicator>Y</EmailNotificationIndicator>'; 
        }
        else{
            body+='<EmailNotificationIndicator>N</EmailNotificationIndicator>'; 
        }
        if(c.NS_Mastered_Contact_Indicator__c == 'Mastered'){//Contact.NS_Mastered_Contact_Indicator__c {for now if it is mastered, then y}
            body+='<MasteredIndicator>Y</MasteredIndicator>';
        }
        else
        {
            body+='<MasteredIndicator>N</MasteredIndicator>';
        }
    //7.2, jlong, revert to hardcode
        body+='<SourceSystem>ConnectNS</SourceSystem>';
        //body+='<SourceSystem>' +c.NSSource_System__c +'</SourceSystem>';
        body+='<ContactStatus>Active</ContactStatus>';
        body+='<AuthorizationStatus/>';
        body+='<StartDate/>';
        body+='<EndDate/>';
        body+='<ContactLastUpdateDate/>';
        body+='<ContactLastUpdateUser/>';
        body+='<WorkPhoneBObj>';
        if(!String.isBlank(workPhone)){
            body+='<WorkPhoneNumber>'+workPhone+'</WorkPhoneNumber>';
            body+='<CountryCode>1</CountryCode>';
            body+='<AreaCode>'+wPhnAreaCode+'</AreaCode>';
            body+='<PhoneNumber>'+wPhone+'</PhoneNumber>';                   
            //body+='<Extension>'+c.NS_Work_Phone_Ext__c+'</Extension>';
            if(String.isBlank(c.NS_Work_Phone_Ext__c)){
                body+='<Extension></Extension>';
            }
            else{
                body+='<Extension>'+c.NS_Work_Phone_Ext__c+'</Extension>'; 
            }
        }else{
            body+='<WorkPhoneNumber/>';
        }
        body+='</WorkPhoneBObj>';
        body+='<MobilePhoneBObj>';
        if(!String.isBlank(mobilePhone)){
            body+='<MobilePhoneNumber>'+mobilePhone+'</MobilePhoneNumber>';
            body+='<CountryCode>1</CountryCode>';
            body+='<AreaCode>'+mPhnAreaCode+'</AreaCode>';
            body+='<PhoneNumber>'+mPhone+'</PhoneNumber>';                   
            if(c.Notification_SMS_Enabled__c){//Contact.Notification_SMS_Enabled__c
                body+='<MobileNotificationIndicator>Y</MobileNotificationIndicator>';
            }
            else{
                body+='<MobileNotificationIndicator>N</MobileNotificationIndicator>';
            }
        }else{
             body+='<MobilePhoneNumber/>';
        }
        body+='</MobilePhoneBObj>';
        body+='<NSIdentifierBObj>';
        body+='<Identifier>EID</Identifier>';
        body+='<IdentifierNumber>'+c.NS_Contact_MDM_EID__c+'</IdentifierNumber>';
        body+='<StartDate/>';
        body+='<EndDate/>';
        body+='<IdentifierLastUpdateDate/>';
        body+='<IdentifierLastUpdateUser/>';
        body+='</NSIdentifierBObj>';
        body+='</NSContactBObj>';
        body+='</TCRMObject>';
        body+='</TCRMTx>';
        body+='</TCRMService>';
        system.debug(body);
        }
        
       // String endpoint ='https://qaapi.nscorp.com/external/connectns-api/mdm';
        //SFCOE-3280 start : Added access token code
        NS_Oauth2 auth = new NS_Oauth2();
        HttpResponse mdmResp;
        String accToken = auth.ReturnAccessToken(auth);
        if(accToken != null){
            if(body != null && body !=''){
                mdmResp = NS_WSCallout.sendRequestRestWithOAUTH(endpointMDM, 'PUT', 'text/xml', accToken, body);
            }
        }
        //HttpResponse mdmResp = NS_WSCallout.sendRequestRest(endpointMDM, 'PUT','text/xml',body);
        //SFCOE-3280 end
         if (mdmResp != null && !String.isBlank(mdmResp.getBody())) {
        DOM.Document doc=new DOM.Document();
        doc.load(mdmResp.getBody());
        DOM.XmlNode rootNode=doc.getRootElement();
        
        for(Dom.XMLNode child : rootNode.getChildElements()) {
            //System.debug(child.getName()); 
            if(child.getName() == 'ResponseControl'){
                for(Dom.XmlNode childElement : child.getChildElements()){
                    //System.debug(childElement.getName());
                    if(childElement.getName() =='ResultCode'){
                        resultCode = childElement.getText();
                    }
                }
            }   
        }
        system.debug('resultCode :> '+resultCode);
        if(resultCode == 'SUCCESS')
        {
            for(Dom.XMLNode child : rootNode.getChildElements()) 
            {
                if(child.getName() == 'TxResponse'){
                    for(Dom.XmlNode secondChildElement : child.getChildElements()){
                        if(secondChildElement.getName() =='ResponseObject'){
                            for(Dom.XmlNode resObjChildElement :secondChildElement.getChildElements()){
                                if(resObjChildElement.getName() =='NSContactBObj'){
                                    for(Dom.XmlNode conObjChildElement :resObjChildElement.getChildElements()){
                                        if(conObjChildElement.getName() =='MasteredIndicator'){
                                            masteredIndicator = conObjChildElement.getText();
                                        }
                                        if(conObjChildElement.getName() =='SourceSystem'){
                                            sourceSystem = conObjChildElement.getText();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        if(resultCode =='SUCCESS'){
         Contact con =[Select id,name,NS_Mastered_Contact_Indicator__c,NS_Contact_MDM_EID__c,NSSource_System__c,NS_Last_MDM_Update_User_RACF__c from Contact where id =: recId];
         
         if(masteredIndicator =='Y'){
             con.NS_Mastered_Contact_Indicator__c = 'Mastered';
         }
         else{
             con.NS_Mastered_Contact_Indicator__c = 'Unmastered';
         }
         //7.2, jlong, do not update sourcesystem field value in sfdc
         //con.NSSource_System__c = sourceSystem;
         con.NS_Last_MDM_Update_User_RACF__c = currentUser.FederationIdentifier;
         update con;
     }        
        }
        return resultCode;
    }
    
     @AuraEnabled 
    public static String sendConToMDMAssociation(id recId, String oldAccountId){
        
        User u = [SELECT Name,FederationIdentifier FROM User where id =: userInfo.getUserId() Limit 01];
        contact c = [select id,FirstName,LastName,AccountId,Phone,Email,MobilePhone,NS_Work_Phone_Ext__c,NS_PreferredName__c,NS_Contact_MDM_EID__c,NS_RACF_ID__c,NS_Mastered_Contact_Indicator__c,NSSource_System__c,NS_AccessNS_Authorization_Status__c,Notification_SMS_Enabled__c,Notification_Email_Enabled__c from contact where id =: recId Limit 01];
        Account acc = [SELECT id,AccountNumber,NS_MDM_EID__c,RecordType.DeveloperName from Account where id =:c.AccountId];
        Account acct = [SELECT id,AccountNumber,NS_MDM_EID__c,RecordType.DeveloperName from Account where id =:oldAccountId];
        
       String ENDPOINT_KEY ='ContactMDMEndpoint';
       String endpointMDM;                                     
       Map<String,NS_Integration_Endpoints__c> endpoints = NS_Integration_Endpoints__c.getAll();  
        if(endpoints.containsKey(ENDPOINT_KEY)){
            endpointMDM = endpoints.get(ENDPOINT_KEY).Endpoint_URL__c;
        }
        
        String response;
        String wPhnAreaCode;
        String wPhone; 
        String mPhnAreaCode;
        String mPhone; 
        String resultCode; 
        String masteredIndicator; 
        String contactEID;  
        String sourceSystem;
        String errorMessage;
        String errorDescription;
        Date sd = System.today()-1;
        Date ed = System.today();
        Datetime todaysdt = System.now();
        String date1 = String.valueOf(todaysdt.date());
        String time1 = String.valueOf(todaysdt.time());
        String year = date1.substring(0,4);
        String month = date1.substring(5,7);
        String day = date1.substring(8,10);
        String hour1 = time1.substring(0,2);
        String min1 = time1.substring(3,5);
        String sec1 = time1.substring(6,8);
        String requestId = year+month+day+hour1+min1+sec1;
        String body;
        
        String workPhone = c.Phone;
        String mobilePhone = c.MobilePhone;
        
         if(!String.isBlank(workPhone) && workPhone.startsWith('1')){
            wPhnAreaCode = workPhone.substring(1,4);
            wPhone = workPhone.substring(4);
        }
       else if(!String.isBlank(workPhone)){
            wPhnAreaCode = workPhone.substring(0,3);
            wPhone = workPhone.substring(3);
        }   
                                               
        if(!String.isBlank(mobilePhone) && mobilePhone.startsWith('1')){
            mPhnAreaCode = mobilePhone.substring(1,4);
            mPhone = mobilePhone.substring(4);
        }
       else if(!String.isBlank(mobilePhone)){
            mPhnAreaCode = mobilePhone.substring(0,3);
            mPhone = mobilePhone.substring(3);
        } 
        if(c.NS_Contact_MDM_EID__c != null && !c.NS_Contact_MDM_EID__c.toLowerCase().contains('old')) {
        if ((acc.RecordType.DeveloperName == 'NS_OnlineCustomerCorporate' || acc.AccountNumber != null) && acc.NS_MDM_EID__c != null && !acc.NS_MDM_EID__c.toLowerCase().contains('old')) {
            body ='<?xml version="1.0" encoding="UTF-8"?>';
            body+='<TCRMService xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ';
            body+='xmlns="http://www.ibm.com/mdm/schema" xsi:schemaLocation="http://www.ibm.com/mdm/schema MDMDomains.xsd">';
            body+='<RequestControl>';
            body+='<requestID>'+requestId+'</requestID>';//contact.id
            body+='<DWLControl>';
            body+='<requesterName>'+u.FederationIdentifier+'</requesterName>';//User.FederationIdentifier
            body+='<requesterLanguage>100</requesterLanguage>';
            body+='</DWLControl>';
            body+='</RequestControl>';
            body+='<TCRMTx>';
            body+='<TCRMTxType>maintainContactAndAccount</TCRMTxType>';
            body+='<TCRMTxObject>ContactAndAccountRequestBObj</TCRMTxObject>';
            body+='<TCRMObject>';
            body+='<ContactAndAccountRequestBObj>';
            body+='<ActionIndicator>Update</ActionIndicator>';
         if(acc.RecordType.DeveloperName == 'NS_OnlineCustomerCorporate'){                                    
            body+='<Relationship>Corporate Contact Association</Relationship>';
         }
         else if(acc.RecordType.DeveloperName == 'NS_OnlineCustomerBusiness' || acc.RecordType.DeveloperName == 'NS_OnlineCustomerService'){
             body+='<Relationship>Location Association</Relationship>';                                      
          }                                      
            body+='<SourceSystem>ConnectNS</SourceSystem>';
            //body+='<SourceSystem>' +c.NSSource_System__c +'</SourceSystem>';
            body+='<StartDate></StartDate>';//TODAY()
            body+='<EndDate></EndDate>';
            body+='<ContactListBObj>';
            body+='<NSContactBObj>';
            body+='<ActionIndicator>Update</ActionIndicator>';
            body+='<FirstName>'+c.FirstName+'</FirstName>';//Contact.FirstName
            body+='<MiddleName></MiddleName>';
            body+='<LastName>'+c.LastName+'</LastName>';
            //body+='<PreferredName>'+c.NS_PreferredName__c+'</PreferredName>';
            if(String.isBlank(c.NS_PreferredName__c)){
                body+='<PreferredName></PreferredName>';
            }else{
                body+='<PreferredName>'+c.NS_PreferredName__c+'</PreferredName>';
            }
            //body+='<Email>'+c.Email+'</Email>';//Email
            if(!String.isBlank(c.Email)){
                body+='<Email>'+c.Email+'</Email>';
            }
        if(c.Notification_Email_Enabled__c){
            body+='<EmailNotificationIndicator>Y</EmailNotificationIndicator>';
        }
        else{
            body+='<EmailNotificationIndicator>N</EmailNotificationIndicator>';
        }
        if(c.NS_Mastered_Contact_Indicator__c == 'Mastered'){
            body+='<MasteredIndicator>Y</MasteredIndicator>';
        }
        else{
            body+='<MasteredIndicator>N</MasteredIndicator>';
        }
            body+='<SourceSystem>ConnectNS</SourceSystem>';
            //body+='<SourceSystem>' +c.NSSource_System__c +'</SourceSystem>';
            body+='<WorkPhoneBObj>';
            if(!String.isBlank(workPhone)){                                    
              body+='<WorkPhoneNumber>'+workPhone+'</WorkPhoneNumber>';
              body+='<CountryCode>1</CountryCode>';
              body+='<AreaCode>'+wPhnAreaCode+'</AreaCode>';
              body+='<PhoneNumber>'+wPhone+'</PhoneNumber>';                
              //body+='<Extension>'+c.NS_Work_Phone_Ext__c+'</Extension>';
                if(String.isBlank(c.NS_Work_Phone_Ext__c)){
                    body+='<Extension></Extension>';
                }
                else{
                    body+='<Extension>'+c.NS_Work_Phone_Ext__c+'</Extension>'; 
                }  
            }else{
                //body+='<WorkPhoneNumber/>';//commented for testing
            }
            body+='</WorkPhoneBObj>';
            body+='<MobilePhoneBObj>';
            if(!String.isBlank(mobilePhone)){                                    
              body+='<MobilePhoneNumber>'+mobilePhone+'</MobilePhoneNumber>';
              body+='<CountryCode>1</CountryCode>';
              body+='<AreaCode>'+mPhnAreaCode+'</AreaCode>';
              body+='<PhoneNumber>'+mPhone+'</PhoneNumber>';                    
               if(c.Notification_SMS_Enabled__c){//Contact.Notification_SMS_Enabled__c
                body+='<MobileNotificationIndicator>Y</MobileNotificationIndicator>';
            }
            else{
                //6.25, mdm require WorkPhoneNumber,MobilePhoneNumber;
                //body+='<MobilePhoneNumber/>';//commented for testing
                body+='<MobileNotificationIndicator>N</MobileNotificationIndicator>';
            }
           }
            body+='</MobilePhoneBObj>';   
            body+='<NSIdentifierBObj>';
            body+='<Identifier>EID</Identifier>';
            body+='<IdentifierNumber>'+c.NS_Contact_MDM_EID__c+'</IdentifierNumber>';//Contact.Id
            body+='<StartDate></StartDate>';//TODAY()
            body+='<EndDate></EndDate>';
            body+='<IdentifierLastUpdateDate></IdentifierLastUpdateDate>';
            body+='<IdentifierLastUpdateUser></IdentifierLastUpdateUser>';
            body+='</NSIdentifierBObj>';
            body+='</NSContactBObj>';
            body+='</ContactListBObj>';
          if(acc.RecordType.DeveloperName == 'NS_OnlineCustomerBusiness' || acc.RecordType.DeveloperName == 'NS_OnlineCustomerService'){                                     
            body+='<Full10AccountListBObj>';
            body+='<Full10BObj>';
            body+='<AccountNumber>'+acc.AccountNumber+'</AccountNumber>';//Contact.Account.AccountNumber
            body+='</Full10BObj>';
            body+='</Full10AccountListBObj>';
          }
          if(acc.RecordType.DeveloperName == 'NS_OnlineCustomerCorporate'){                                      
            body+='<CorporateAccountListBObj>';
            body+='<CorporateAccountBObj>';
            body+='<CorporateMDMEID>'+acc.NS_MDM_EID__c+'</CorporateMDMEID>';//Contact.Account.NS_MDM_EID__c
            body+='</CorporateAccountBObj>';
            body+='</CorporateAccountListBObj>';
          }
            body+='</ContactAndAccountRequestBObj>';
            body+='</TCRMObject>';
            body+='</TCRMTx>';
            body+='</TCRMService>';                                            
           system.debug(body);  
        
        // String endpoint ='https://qaapi.nscorp.com/external/connectns-api/mdm';
            //SFCOE-3280 start : Added access token code
            NS_Oauth2 auth = new NS_Oauth2();
            HttpResponse hres;
            String accToken = auth.ReturnAccessToken(auth);
            if(accToken != null){
                hres = NS_WSCallout.sendRequestRestWithOAUTH(endpointMDM, 'PUT', 'text/xml', accToken, body);
            }
            //HttpResponse hres = NS_WSCallout.sendRequestRest(endpointMDM, 'PUT','text/xml',body);
            //SFCOE-3280 end
         System.debug('Response' +hres.getBody());
        
        String xmlResponse = hres.getBody();
   DOM.Document doc=new DOM.Document();
      doc.load(xmlResponse);
      DOM.XmlNode rootNode=doc.getRootElement();
      
      for(Dom.XMLNode child : rootNode.getChildElements()) {
        //System.debug(child.getName()); 
      if(child.getName() == 'ResponseControl'){
        for(Dom.XmlNode childElement : child.getChildElements()){
        //System.debug(childElement.getName());
            if(childElement.getName() =='ResultCode'){
                resultCode = childElement.getText();
            }
           }
         }   
      }
        
         if(resultCode =='SUCCESS'){
        for(Dom.XMLNode child : rootNode.getChildElements()) {
            if(child.getName() == 'TxResponse'){
                for(Dom.XmlNode secondChildElement : child.getChildElements()){
                    if(secondChildElement.getName() =='ResponseObject'){
                        for(Dom.XmlNode resObjChildElement :secondChildElement.getChildElements()){
                           // system.debug(resObjChildElement.getName());
                            if(resObjChildElement.getName() =='ContactAndAccountResponseBObj'){
                                for(Dom.XmlNode conAccObjChildElement :resObjChildElement.getChildElements()){
                                    if(conAccObjChildElement.getName() =='ContactAndAccountBObj'){
                                for(Dom.XmlNode conObjChildElement :conAccObjChildElement.getChildElements()){
                                    if(conObjChildElement.getName() =='MasteredIndicator'){
                                        masteredIndicator = conObjChildElement.getText();
                                    }
                                    if(conObjChildElement.getName() =='SourceSystem'){
                                        sourceSystem = conObjChildElement.getText();
                                    }
                                }
                                }
                            }
                            }
                        }
                    }
                }
            }
        }  
    }

     if(resultCode =='FATAL'){
         for(Dom.XMLNode child : rootNode.getChildElements()) {
            if(child.getName() == 'TxResponse'){
                for(Dom.XmlNode secondChildElement : child.getChildElements()){
                    if(secondChildElement.getName() == 'TxResult'){
                        for(Dom.XmlNode txResultElement : secondChildElement.getChildElements()){
                            if(txResultElement.getName() == 'DWLError'){
                               for(Dom.XmlNode errorElement : txResultElement.getChildElements()){ 
                                    if(errorElement.getName() == 'ErrorMessage'){
                                         errorMessage = errorElement.getText();
                                    }
                                    if(errorElement.getName() == 'Throwable'){
                                        errorDescription = errorElement.getText();
                                    }
                                } 
                            }
                        }
                    }
                }
            }
         }
     } 
            if(acct.AccountNumber != Null){
 // Delete Association 
        if(acct.RecordType.DeveloperName == 'NS_OnlineCustomerCorporate'){
            String delBody = '';
            delBody+='<TCRMService xsi:schemaLocation="http://www.ibm.com/mdm/schema MDMDomains.xsd" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.ibm.com/mdm/schema">';
            delBody+='<RequestControl>';
            delBody+='<requestID>'+requestId+'</requestID>';
            delBody+='<DWLControl>';
            delBody+='<requesterName>'+u.FederationIdentifier+'</requesterName>';
            delBody+='<requesterLanguage>100</requesterLanguage>';
            delBody+='</DWLControl>';
            delBody+='</RequestControl>';
            delBody+='<TCRMTx>';
            delBody+='<TCRMTxType>maintainPartyRelationship</TCRMTxType>';
            delBody+='<TCRMTxObject>NSPatyRelationshipBObj</TCRMTxObject>';
            delBody+='<TCRMObject>';
            delBody+='<NSPatyRelationshipBObj>';
            delBody+='<ActionIndicator>Delete</ActionIndicator>';
            delBody+='<FromMDMEID>'+c.NS_Contact_MDM_EID__c+'</FromMDMEID>';
            delBody+='<ToMDMEID>'+acct.NS_MDM_EID__c+'</ToMDMEID>';
            delBody+='<Relationship>Corporate Contact Association</Relationship>';
            delBody+='<SourceSystem>ConnectNS</SourceSystem>';
            //delBody+='<SourceSystem>' +c.NSSource_System__c +'</SourceSystem>';
            delBody+='</NSPatyRelationshipBObj>';
            delBody+='</TCRMObject>';
            delBody+='</TCRMTx>';
            delBody+='</TCRMService>';
            System.debug(delBody);
            //SFCOE-3280 start : Added access token code
            NS_Oauth2 auth1 = new NS_Oauth2();
            HttpResponse delHres;
            String accToken1 = auth1.ReturnAccessToken(auth1);
            if(accToken1 != null){
                delHres = NS_WSCallout.sendRequestRestWithOAUTH(endpointMDM, 'PUT', 'text/xml', accToken1, delBody);
            }
            //HttpResponse delHres = NS_WSCallout.sendRequestRest(endpointMDM, 'PUT','text/xml',delBody);
            //SFCOE-3280 end
            System.debug('Response' +delHres.getBody());
        }
        else{
            String delBody ='<?xml version="1.0" encoding="UTF-8"?>';
            delBody +='<TCRMService xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.ibm.com/mdm/schema" xsi:schemaLocation="http://www.ibm.com/mdm/schema MDMDomains.xsd">';
            delBody +='<RequestControl>';
            delBody +='<requestID>'+requestId+'</requestID>';
            delBody +='<DWLControl>';
            delBody +='<requesterName>'+u.FederationIdentifier+'</requesterName>';
            delBody +='<requesterLanguage>100</requesterLanguage>';
            delBody +='</DWLControl>';
            delBody +='</RequestControl>';
            delBody +='<TCRMTx>';
            delBody +='<TCRMTxType>maintainAccount</TCRMTxType>';
            delBody +='<TCRMTxObject>NSAccountBObj</TCRMTxObject>';
            delBody +='<TCRMObject>';
            delBody +='<NSAccountBObj>';
            delBody +='<ActionIndicator>Delete</ActionIndicator>';
            delBody +='<Relationship>Location Association</Relationship>';
            /*if(acct.RecordType.DeveloperName == 'NS_OnlineCustomerCorporate'){                                    
                delBody+='<Relationship>Corporate Contact Association</Relationship>';
            }
            else if(acct.RecordType.DeveloperName == 'NS_OnlineCustomerBusiness' || acct.RecordType.DeveloperName == 'NS_OnlineCustomerService'){
                delBody+='<Relationship>Location Association</Relationship>';                                      
            }*/  
            delBody +='<SourceSystem>ConnectNS</SourceSystem>';
            //delBody +='<SourceSystem>'+c.NSSource_System__c+'</SourceSystem>';
            //delBody +='<StartDate>'+sd+'</StartDate>';
            //delBody +='<EndDate>'+ed+'</EndDate>';
            delBody +='<ThreePLListBObj/>';
            delBody +='<ContactEIDListBObj>';
            delBody +='<ContactEIDBObj>';
            delBody +='<ContactMDMEID>'+c.NS_Contact_MDM_EID__c+'</ContactMDMEID>';
            delBody +='</ContactEIDBObj>';
            delBody +='</ContactEIDListBObj>';
            delBody +='<AccountListBObj>';
            //if(acct.RecordType.DeveloperName == 'NS_OnlineCustomerBusiness' || acct.RecordType.DeveloperName == 'NS_OnlineCustomerService'){
                delBody +='<Full10BObj>';
                delBody +='<AccountNumber>'+acct.AccountNumber+'</AccountNumber>';
                delBody +='</Full10BObj>';
            //}
            /*if(acct.RecordType.DeveloperName == 'NS_OnlineCustomerCorporate'){                                      
                delBody+='<CorporateAccountBObj>';
                delBody+='<CorporateMDMEID>'+acct.NS_MDM_EID__c+'</CorporateMDMEID>';//Contact.Account.NS_MDM_EID__c
                delBody+='</CorporateAccountBObj>';
            }*/
            delBody +='</AccountListBObj>';
            delBody +='</NSAccountBObj>';
            delBody +='</TCRMObject>';
            delBody +='</TCRMTx>';
            delBody +='</TCRMService>'; 
            System.debug(delBody);
            
            //SFCOE-3280 start : Added access token code
            NS_Oauth2 auth2 = new NS_Oauth2();
            HttpResponse delHres;
            String accToken2 = auth2.ReturnAccessToken(auth2);
            if(accToken2 != null){
                delHres = NS_WSCallout.sendRequestRestWithOAUTH(endpointMDM, 'PUT', 'text/xml', accToken2, delBody);
            }
            //HttpResponse delHres = NS_WSCallout.sendRequestRest(endpointMDM, 'PUT','text/xml',delBody);
            //SFCOE-3280 end
            System.debug('Response' +delHres.getBody());
            
        }
        }
        }
        }
        if(c.NS_Contact_MDM_EID__c != null && !c.NS_Contact_MDM_EID__c.toLowerCase().contains('old')) {
        else if(acc.AccountNumber == null && acc.NS_MDM_EID__c != null && !acc.NS_MDM_EID__c.toLowerCase().contains('old')){
            
            string body='<?xml version="1.0" encoding="UTF-8"?>';
            body+='<TCRMService xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.ibm.com/mdm/schema" xsi:schemaLocation="http://www.ibm.com/mdm/schema MDMDomains.xsd">';
            body+='<RequestControl>';
            body+='<requestID>'+requestId+'</requestID>';
            body+='<DWLControl>';
            body+='<requesterName>'+u.FederationIdentifier+'</requesterName>';
            body+='<requesterLanguage>100</requesterLanguage>';
            body+='</DWLControl>';
            body+='</RequestControl>';
            body+='<TCRMTx>';
            body+='<TCRMTxType>maintainContact</TCRMTxType>';
            body+='<TCRMTxObject>NSContactBObj</TCRMTxObject>';
            body+='<TCRMObject>';
            body+='<NSContactBObj>';
            body+='<ActionIndicator>Update</ActionIndicator>';
            body+='<FirstName>'+c.FirstName+'</FirstName>';
            body+='<LastName>'+c.LastName+'</LastName>';
            //body+='<PreferredName>'+c.NS_PreferredName__c+'</PreferredName>';
            if(String.isBlank(c.NS_PreferredName__c)){
                body+='<PreferredName></PreferredName>';
            }else{
                body+='<PreferredName>'+c.NS_PreferredName__c+'</PreferredName>';
            }
            //body+='<Email>'+c.Email+'</Email>';
            if(!String.isBlank(c.Email)){
                body+='<Email>'+c.Email+'</Email>';
            }
            if(c.Notification_Email_Enabled__c){//Contact.Notification_Email_Enabled__c
                body+='<EmailNotificationIndicator>Y</EmailNotificationIndicator>'; 
            }
            else{
                body+='<EmailNotificationIndicator>N</EmailNotificationIndicator>'; 
            }
            if(c.NS_Mastered_Contact_Indicator__c == 'Mastered'){//Contact.NS_Mastered_Contact_Indicator__c {for now if it is mastered, then y}
                body+='<MasteredIndicator>Y</MasteredIndicator>';
            }
            else
            {
                body+='<MasteredIndicator>N</MasteredIndicator>';
            }
            body+='<SourceSystem>ConnectNS</SourceSystem>';
            //body+='<SourceSystem>' +c.NSSource_System__c +'</SourceSystem>';
            body+='<ContactStatus>Active</ContactStatus>';
            body+='<AuthorizationStatus/>';
            body+='<StartDate/>';
            body+='<EndDate/>';
            body+='<ContactLastUpdateDate/>';
            body+='<ContactLastUpdateUser/>';
            body+='<WorkPhoneBObj>';
            if(!String.isBlank(workPhone)){
                body+='<WorkPhoneNumber>'+workPhone+'</WorkPhoneNumber>';
                body+='<CountryCode>1</CountryCode>';
                body+='<AreaCode>'+wPhnAreaCode+'</AreaCode>';
                body+='<PhoneNumber>'+wPhone+'</PhoneNumber>';                   
                //body+='<Extension>'+c.NS_Work_Phone_Ext__c+'</Extension>';
                if(String.isBlank(c.NS_Work_Phone_Ext__c)){
                    body+='<Extension></Extension>';
                }
                else{
                    body+='<Extension>'+c.NS_Work_Phone_Ext__c+'</Extension>'; 
                }
            }else{
                body+='<WorkPhoneNumber/>';
            }
            body+='</WorkPhoneBObj>';
            body+='<MobilePhoneBObj>';
            if(!String.isBlank(mobilePhone)){
                body+='<MobilePhoneNumber>'+mobilePhone+'</MobilePhoneNumber>';
                body+='<CountryCode>1</CountryCode>';
                body+='<AreaCode>'+mPhnAreaCode+'</AreaCode>';
                body+='<PhoneNumber>'+mPhone+'</PhoneNumber>';                   
                if(c.Notification_SMS_Enabled__c){//Contact.Notification_SMS_Enabled__c
                    body+='<MobileNotificationIndicator>Y</MobileNotificationIndicator>';
                }
                else{
                    body+='<MobileNotificationIndicator>N</MobileNotificationIndicator>';
                }
            }
            body+='</MobilePhoneBObj>';
            body+='<NSIdentifierBObj>';
            body+='<Identifier>EID</Identifier>';
            body+='<IdentifierNumber>'+c.NS_Contact_MDM_EID__c+'</IdentifierNumber>';
            body+='<StartDate/>';
            body+='<EndDate/>';
            body+='<IdentifierLastUpdateDate/>';
            body+='<IdentifierLastUpdateUser/>';
            body+='</NSIdentifierBObj>';
            body+='</NSContactBObj>';
            body+='</TCRMObject>';
            body+='</TCRMTx>';
            body+='</TCRMService>';
            system.debug(body);
            
            // String endpoint ='https://qaapi.nscorp.com/external/connectns-api/mdm';
            //SFCOE-3280 start : Added access token code
            NS_Oauth2 auth = new NS_Oauth2();
            HttpResponse mdmResp;
            String accToken = auth.ReturnAccessToken(auth);
            if(accToken != null){
                mdmResp = NS_WSCallout.sendRequestRestWithOAUTH(endpointMDM, 'PUT', 'text/xml', accToken, body);
            }
            //HttpResponse mdmResp = NS_WSCallout.sendRequestRest(endpointMDM, 'PUT','text/xml',body);
            //SFCOE-3280 end
            
            DOM.Document doc=new DOM.Document();
            doc.load(mdmResp.getBody());
            DOM.XmlNode rootNode=doc.getRootElement();
            
            for(Dom.XMLNode child : rootNode.getChildElements()) {
                //System.debug(child.getName()); 
                if(child.getName() == 'ResponseControl'){
                    for(Dom.XmlNode childElement : child.getChildElements()){
                        //System.debug(childElement.getName());
                        if(childElement.getName() =='ResultCode'){
                            resultCode = childElement.getText();
                        }
                    }
                }   
            }
            system.debug('resultCode :> '+resultCode);
            if(resultCode == 'SUCCESS')
            {
                for(Dom.XMLNode child : rootNode.getChildElements()) 
                {
                    if(child.getName() == 'TxResponse'){
                        for(Dom.XmlNode secondChildElement : child.getChildElements()){
                            if(secondChildElement.getName() =='ResponseObject'){
                                for(Dom.XmlNode resObjChildElement :secondChildElement.getChildElements()){
                                    if(resObjChildElement.getName() =='NSContactBObj'){
                                        for(Dom.XmlNode conObjChildElement :resObjChildElement.getChildElements()){
                                            if(conObjChildElement.getName() =='MasteredIndicator'){
                                                masteredIndicator = conObjChildElement.getText();
                                            }
                                            if(conObjChildElement.getName() =='SourceSystem'){
                                                sourceSystem = conObjChildElement.getText();
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            if(resultCode =='FATAL'){
                for(Dom.XMLNode child : rootNode.getChildElements()) {
                    if(child.getName() == 'TxResponse'){
                        for(Dom.XmlNode secondChildElement : child.getChildElements()){
                            if(secondChildElement.getName() == 'TxResult'){
                                for(Dom.XmlNode txResultElement : secondChildElement.getChildElements()){
                                    if(txResultElement.getName() == 'DWLError'){
                                        for(Dom.XmlNode errorElement : txResultElement.getChildElements()){ 
                                            if(errorElement.getName() == 'ErrorMessage'){
                                                errorMessage = errorElement.getText();
                                            }
                                            if(errorElement.getName() == 'Throwable'){
                                                errorDescription = errorElement.getText();
                                            }
                                        } 
                                    }
                                }
                            }
                        }
                    }
                }
            }
            if(acct.AccountNumber != Null){
            //if(!(acct.AccountNumber == Null && acc.AccountNumber != null)){
            // // Delete Association
            System.debug('HERE::::'); 
            if(acct.RecordType.DeveloperName == 'NS_OnlineCustomerCorporate'){
                String delBody = '';
                delBody+='<TCRMService xsi:schemaLocation="http://www.ibm.com/mdm/schema MDMDomains.xsd" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.ibm.com/mdm/schema">';
                delBody+='<RequestControl>';
                delBody+='<requestID>'+requestId+'</requestID>';
                delBody+='<DWLControl>';
                delBody+='<requesterName>'+u.FederationIdentifier+'</requesterName>';
                delBody+='<requesterLanguage>100</requesterLanguage>';
                delBody+='</DWLControl>';
                delBody+='</RequestControl>';
                delBody+='<TCRMTx>';
                delBody+='<TCRMTxType>maintainPartyRelationship</TCRMTxType>';
                delBody+='<TCRMTxObject>NSPatyRelationshipBObj</TCRMTxObject>';
                delBody+='<TCRMObject>';
                delBody+='<NSPatyRelationshipBObj>';
                delBody+='<ActionIndicator>Delete</ActionIndicator>';
                delBody+='<FromMDMEID>'+c.NS_Contact_MDM_EID__c+'</FromMDMEID>';
                delBody+='<ToMDMEID>'+acct.NS_MDM_EID__c+'</ToMDMEID>';
                delBody+='<Relationship>Corporate Contact Association</Relationship>';
                delBody+='<SourceSystem>ConnectNS</SourceSystem>';
                delBody+='</NSPatyRelationshipBObj>';
                delBody+='</TCRMObject>';
                delBody+='</TCRMTx>';
                delBody+='</TCRMService>';
                System.debug(delBody);
                //SFCOE-3280 start : Added access token code
                NS_Oauth2 auth3 = new NS_Oauth2();
                HttpResponse delHres;
                String accToken3 = auth3.ReturnAccessToken(auth3);
                if(accToken3 != null){
                    delHres = NS_WSCallout.sendRequestRestWithOAUTH(endpointMDM, 'PUT', 'text/xml', accToken3, delBody);
                }
                //HttpResponse delHres = NS_WSCallout.sendRequestRest(endpointMDM, 'PUT','text/xml',delBody);
                //SFCOE-3280 end
                System.debug('Response' +delHres.getBody());
            }
            else{
                String delBody ='<?xml version="1.0" encoding="UTF-8"?>';
                delBody +='<TCRMService xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.ibm.com/mdm/schema" xsi:schemaLocation="http://www.ibm.com/mdm/schema MDMDomains.xsd">';
                delBody +='<RequestControl>';
                delBody +='<requestID>'+requestId+'</requestID>';
                delBody +='<DWLControl>';
                delBody +='<requesterName>'+u.FederationIdentifier+'</requesterName>';
                delBody +='<requesterLanguage>100</requesterLanguage>';
                delBody +='</DWLControl>';
                delBody +='</RequestControl>';
                delBody +='<TCRMTx>';
                delBody +='<TCRMTxType>maintainAccount</TCRMTxType>';
                delBody +='<TCRMTxObject>NSAccountBObj</TCRMTxObject>';
                delBody +='<TCRMObject>';
                delBody +='<NSAccountBObj>';
                delBody +='<ActionIndicator>Delete</ActionIndicator>';
                delBody +='<Relationship>Location Association</Relationship>';
                /*if(acct.RecordType.DeveloperName == 'NS_OnlineCustomerCorporate'){                                    
delBody+='<Relationship>Corporate Contact Association</Relationship>';
}
else if(acct.RecordType.DeveloperName == 'NS_OnlineCustomerBusiness' || acct.RecordType.DeveloperName == 'NS_OnlineCustomerService'){
delBody+='<Relationship>Location Association</Relationship>';                                      
}*/  
                delBody +='<SourceSystem>ConnectNS</SourceSystem>';
                //delBody +='<StartDate>'+sd+'</StartDate>';
                //delBody +='<EndDate>'+ed+'</EndDate>';
                delBody +='<ThreePLListBObj/>';
                delBody +='<ContactEIDListBObj>';
                delBody +='<ContactEIDBObj>';
                delBody +='<ContactMDMEID>'+c.NS_Contact_MDM_EID__c+'</ContactMDMEID>';
                delBody +='</ContactEIDBObj>';
                delBody +='</ContactEIDListBObj>';
                delBody +='<AccountListBObj>';
                //if(acct.RecordType.DeveloperName == 'NS_OnlineCustomerBusiness' || acct.RecordType.DeveloperName == 'NS_OnlineCustomerService'){
                delBody +='<Full10BObj>';
                delBody +='<AccountNumber>'+acct.AccountNumber+'</AccountNumber>';
                delBody +='</Full10BObj>';
                //}
                /*if(acct.RecordType.DeveloperName == 'NS_OnlineCustomerCorporate'){                                      
delBody+='<CorporateAccountBObj>';
delBody+='<CorporateMDMEID>'+acct.NS_MDM_EID__c+'</CorporateMDMEID>';//Contact.Account.NS_MDM_EID__c
delBody+='</CorporateAccountBObj>';
}*/
                delBody +='</AccountListBObj>';
                delBody +='</NSAccountBObj>';
                delBody +='</TCRMObject>';
                delBody +='</TCRMTx>';
                delBody +='</TCRMService>'; 
                System.debug(delBody);
                
                //SFCOE-3280 start : Added access token code
                NS_Oauth2 auth4 = new NS_Oauth2();
                HttpResponse delHres;
                String accToken4 = auth4.ReturnAccessToken(auth4);
                if(accToken4 != null){
                    delHres = NS_WSCallout.sendRequestRestWithOAUTH(endpointMDM, 'PUT', 'text/xml', accToken4, delBody);
                }
                //HttpResponse delHres = NS_WSCallout.sendRequestRest(endpointMDM, 'PUT','text/xml',delBody);
                //SFCOE-3280 end
                System.debug('Response' +delHres.getBody());
            }
            }
        }
        }
              
          if(resultCode =='SUCCESS'){
         Contact con =[Select id,name,NS_Mastered_Contact_Indicator__c,NS_Contact_MDM_EID__c,NSSource_System__c,NS_Last_MDM_Update_User_RACF__c from Contact where id=:recId];
         
         if(masteredIndicator =='Y'){
             con.NS_Mastered_Contact_Indicator__c = 'Mastered';
         }
         else{
             con.NS_Mastered_Contact_Indicator__c = 'Unmastered';
         }
         //con.NS_Contact_MDM_EID__c = contactEID;
         //con.NSSource_System__c = sourceSystem;
         con.NS_Last_MDM_Update_User_RACF__c = u.FederationIdentifier;
         update con;
     }  
        
         if(resultCode =='FATAL'){
        Exception__c excep = new Exception__c();
        if(errorMessage.length()<80){
        excep.Name = errorMessage;
        }else{
            excep.Name=  errorMessage.substring(0, 79);
        } 
        excep.Class_Name__c = 'NS_GeneralContactEditFormController';
        excep.Method_Name__c = 'sendConToMDMAssociation'; 
        if(errorDescription.length()<255){
            excep.Description__c = errorDescription;
        }else{
            excep.Description__c=  errorDescription.substring(0, 254);
        } 
        insert excep;
      }
        //Pre-ExceptionCatcher
    if(acc.RecordType.DeveloperName == 'NS_OnlineCustomerBusiness' || acc.RecordType.DeveloperName == 'NS_OnlineCustomerService')
         {
             if(String.isBlank(acc.AccountNumber))
             {
                 Exception__c excep = new Exception__c();
                 excep.Name = 'Account Number is blank';
                 excep.Class_Name__c = 'NS_GeneralContactEditFormController';
                 excep.Method_Name__c = 'sendConToMDMAssociation'; 
                 excep.Description__c = 'We cannot sent the contact to MDM if account number is blank';
                 insert excep;
             }
         }
         else if(acc.RecordType.DeveloperName == 'NS_OnlineCustomerCorporate'){
             if(String.isBlank(acc.NS_MDM_EID__c)){
                 Exception__c excep = new Exception__c();
                 excep.Name = 'MDM EID is blank';
                 excep.Class_Name__c = 'NS_GeneralContactEditFormController';
                 excep.Method_Name__c = 'sendConToMDMAssociation'; 
                 excep.Description__c = 'We cannot sent the contact to MDM if MDM EID is blank';
                 insert excep;
             }                                  
         }
        //End_Pre-ExceptionCatcher
        return response;
    }
    
     // Method to Send Contact Record to MDM   
    @AuraEnabled
    public static String sendContactRequest(Id contactId){
                                            
       String ENDPOINT_KEY ='ContactMDMEndpoint';
       String endpointMDM;                                     
       Map<String,NS_Integration_Endpoints__c> endpoints = NS_Integration_Endpoints__c.getAll();  
        if(endpoints.containsKey(ENDPOINT_KEY)){
            endpointMDM = endpoints.get(ENDPOINT_KEY).Endpoint_URL__c;
        }
    
        String response;
        String wPhnAreaCode;
        String wPhone; 
        String mPhnAreaCode;
        String mPhone; 
        String resultCode; 
        String masteredIndicator; 
        String contactEID;  
        String sourceSystem; 
        String errorMessage;
        String errorDescription;
       // List<string> identifierNumber=new List<string>();
        Datetime todaysdt = System.now();
        String date1 = String.valueOf(todaysdt.date());
        String time1 = String.valueOf(todaysdt.time());
        String year = date1.substring(0,4);
        String month = date1.substring(5,7);
        String day = date1.substring(8,10);
        String hour1 = time1.substring(0,2);
        String min1 = time1.substring(3,5);
        String sec1 = time1.substring(6,8);
        String requestId = year+month+day+hour1+min1+sec1;
        String body;
       // System.debug(requestId);

        contact c = [select id,FirstName,LastName,AccountId,NSSource_System__c,Phone,Email,MobilePhone,NS_Work_Phone_Ext__c,NS_PreferredName__c,NS_Contact_MDM_EID__c,NS_RACF_ID__c,NS_Mastered_Contact_Indicator__c,NS_AccessNS_Authorization_Status__c,Notification_SMS_Enabled__c,Notification_Email_Enabled__c from contact where id =: contactId Limit 01];
         
        User u = [SELECT FederationIdentifier FROM User where id =: userInfo.getUserId() Limit 01];
        Account acc = [SELECT id,AccountNumber,NS_MDM_EID__c,RecordType.DeveloperName from Account where id =:c.AccountId];
        
        String workPhone = c.Phone;
        String mobilePhone = c.MobilePhone;
         
        if(!String.isBlank(workPhone) && workPhone.startsWith('1')){
            wPhnAreaCode = workPhone.substring(1,4);
            wPhone = workPhone.substring(4);
        }
       else if(!String.isBlank(workPhone)){
            wPhnAreaCode = workPhone.substring(0,3);
            wPhone = workPhone.substring(3);
        }   
                                               
        if(!String.isBlank(mobilePhone) && mobilePhone.startsWith('1')){
            mPhnAreaCode = mobilePhone.substring(1,4);
            mPhone = mobilePhone.substring(4);
        }
       else if(!String.isBlank(mobilePhone)){
            mPhnAreaCode = mobilePhone.substring(0,3);
            mPhone = mobilePhone.substring(3);
        } 
        if(c.NS_Contact_MDM_EID__c != null && !c.NS_Contact_MDM_EID__c.toLowerCase().contains('old')) {                                       
            body ='<?xml version="1.0" encoding="UTF-8"?>';
            body+='<TCRMService xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ';
            body+='xmlns="http://www.ibm.com/mdm/schema" xsi:schemaLocation="http://www.ibm.com/mdm/schema MDMDomains.xsd">';
            body+='<RequestControl>';
            body+='<requestID>'+requestId+'</requestID>';//contact.id
            body+='<DWLControl>';
            body+='<requesterName>'+u.FederationIdentifier+'</requesterName>';//User.FederationIdentifier
            body+='<requesterLanguage>100</requesterLanguage>';
            body+='</DWLControl>';
            body+='</RequestControl>';
            body+='<TCRMTx>';
            body+='<TCRMTxType>maintainContactAndAccount</TCRMTxType>';
            body+='<TCRMTxObject>ContactAndAccountRequestBObj</TCRMTxObject>';
            body+='<TCRMObject>';
            body+='<ContactAndAccountRequestBObj>';
            body+='<ActionIndicator>Add</ActionIndicator>';
         if(acc.RecordType.DeveloperName == 'NS_OnlineCustomerCorporate'){                                    
            body+='<Relationship>Corporate Contact Association</Relationship>';
         }
         else if(acc.RecordType.DeveloperName == 'NS_OnlineCustomerBusiness' || acc.RecordType.DeveloperName == 'NS_OnlineCustomerService'){
             body+='<Relationship>Location Association</Relationship>';                                      
          }                                      
            body+='<SourceSystem>ConnectNS</SourceSystem>';
            body+='<StartDate></StartDate>';//TODAY()
            body+='<EndDate></EndDate>';
            body+='<ContactListBObj>';
            body+='<NSContactBObj>';
            body+='<ActionIndicator>Add</ActionIndicator>';
            body+='<FirstName>'+c.FirstName+'</FirstName>';//Contact.FirstName
            body+='<MiddleName></MiddleName>';
            body+='<LastName>'+c.LastName+'</LastName>';
            //body+='<PreferredName>'+c.NS_PreferredName__c+'</PreferredName>';
            if(String.isBlank(c.NS_PreferredName__c)){
                body+='<PreferredName></PreferredName>';
            }else{
                body+='<PreferredName>'+c.NS_PreferredName__c+'</PreferredName>';
            }
          //body+='<Email>'+c.Email+'</Email>';//Email
            if(!String.isBlank(c.Email)){
                body+='<Email>'+c.Email+'</Email>';
            }    
            body+='<EmailNotificationIndicator>N</EmailNotificationIndicator>';
            body+='<MasteredIndicator>N</MasteredIndicator>';
            body+='<SourceSystem>ConnectNS</SourceSystem>';
            //body+='<ContactStatus></ContactStatus>';
            //body+='<AuthorizationStatus></AuthorizationStatus>';
           // body+='<StartDate></StartDate>';//TODAY()
           // body+='<EndDate></EndDate>';
           // body+='<ContactLastUpdateDate></ContactLastUpdateDate>';//TODAY()
           // body+='<ContactLastUpdateUser>null</ContactLastUpdateUser>';//User.FederationIdentifier
            body+='<WorkPhoneBObj>';
            if(!String.isBlank(workPhone)){                                    
              body+='<WorkPhoneNumber>'+workPhone+'</WorkPhoneNumber>';
              body+='<CountryCode>1</CountryCode>';
              body+='<AreaCode>'+wPhnAreaCode+'</AreaCode>';
              body+='<PhoneNumber>'+wPhone+'</PhoneNumber>';                
              //body+='<Extension>'+c.NS_Work_Phone_Ext__c+'</Extension>';
                if(String.isBlank(c.NS_Work_Phone_Ext__c)){
                    body+='<Extension></Extension>';
                }
                else{
                    body+='<Extension>'+c.NS_Work_Phone_Ext__c+'</Extension>'; 
                }
            }else{
                body+='<WorkPhoneNumber/>';
            }
            body+='</WorkPhoneBObj>';
            body+='<MobilePhoneBObj>';
            if(!String.isBlank(mobilePhone)){                                    
              body+='<MobilePhoneNumber>'+mobilePhone+'</MobilePhoneNumber>';
              body+='<CountryCode>1</CountryCode>';
              body+='<AreaCode>'+mPhnAreaCode+'</AreaCode>';
              body+='<PhoneNumber>'+mPhone+'</PhoneNumber>';                    
              body+='<MobileNotificationIndicator>N</MobileNotificationIndicator>';
            }else{
                body+='<MobilePhoneNumber/>';
            }
            body+='</MobilePhoneBObj>';   
            body+='<NSIdentifierBObj>';
            body+='<Identifier>Salesforce ID</Identifier>';
            body+='<IdentifierNumber>'+contactId+'</IdentifierNumber>';//Contact.Id
            body+='<StartDate></StartDate>';//TODAY()
            body+='<EndDate></EndDate>';
            body+='<IdentifierLastUpdateDate></IdentifierLastUpdateDate>';
            body+='<IdentifierLastUpdateUser></IdentifierLastUpdateUser>';
            body+='</NSIdentifierBObj>';
            body+='</NSContactBObj>';
            body+='</ContactListBObj>';
          if(acc.RecordType.DeveloperName == 'NS_OnlineCustomerBusiness' || acc.RecordType.DeveloperName == 'NS_OnlineCustomerService'){                                     
            body+='<Full10AccountListBObj>';
            body+='<Full10BObj>';
            body+='<AccountNumber>'+acc.AccountNumber+'</AccountNumber>';//Contact.Account.AccountNumber
            body+='</Full10BObj>';
            body+='</Full10AccountListBObj>';
          }
          if(acc.RecordType.DeveloperName == 'NS_OnlineCustomerCorporate'){                                      
            body+='<CorporateAccountListBObj>';
            body+='<CorporateAccountBObj>';
            body+='<CorporateMDMEID>'+acc.NS_MDM_EID__c+'</CorporateMDMEID>';//Contact.Account.NS_MDM_EID__c
            body+='</CorporateAccountBObj>';
            body+='</CorporateAccountListBObj>';
          }
            body+='</ContactAndAccountRequestBObj>';
            body+='</TCRMObject>';
            body+='</TCRMTx>';
            body+='</TCRMService>';                                            
           system.debug(body);
        } 
                                               
     //  String endpoint ='https://qaapi.nscorp.com/external/connectns-api/mdm';
        //SFCOE-3280 start : Added access token code
        NS_Oauth2 auth = new NS_Oauth2();
        HttpResponse hres;
        String accToken = auth.ReturnAccessToken(auth);
        if(accToken != null){
            if(body != null && body !=''){
                hres = NS_WSCallout.sendRequestRestWithOAUTH(endpointMDM, 'PUT', 'text/xml', accToken, body);
            }
        }
        //HttpResponse hres = NS_WSCallout.sendRequestRest(endpointMDM, 'PUT','text/xml',body);
        //SFCOE-3280 end
        System.debug('Response ' + (hres != null ? hres.getBody() : 'null'));
     
    if (mdmResp != null && !String.isBlank(mdmResp.getBody())) {      
   String xmlResponse = hres.getBody();
   DOM.Document doc=new DOM.Document();
      doc.load(xmlResponse);
      DOM.XmlNode rootNode=doc.getRootElement();
      
      for(Dom.XMLNode child : rootNode.getChildElements()) {
        //System.debug(child.getName()); 
      if(child.getName() == 'ResponseControl'){
        for(Dom.XmlNode childElement : child.getChildElements()){
        //System.debug(childElement.getName());
            if(childElement.getName() =='ResultCode'){
                resultCode = childElement.getText();
            }
           }
         }   
      }
     
    if(resultCode =='SUCCESS'){
        for(Dom.XMLNode child : rootNode.getChildElements()) {
            if(child.getName() == 'TxResponse'){
                for(Dom.XmlNode secondChildElement : child.getChildElements()){
                    if(secondChildElement.getName() =='ResponseObject'){
                        for(Dom.XmlNode resObjChildElement :secondChildElement.getChildElements()){
                           // system.debug(resObjChildElement.getName());
                            if(resObjChildElement.getName() =='ContactAndAccountResponseBObj'){
                                for(Dom.XmlNode conAccObjChildElement :resObjChildElement.getChildElements()){
                                    if(conAccObjChildElement.getName() =='ContactAndAccountBObj'){
                                for(Dom.XmlNode conObjChildElement :conAccObjChildElement.getChildElements()){
                                    if(conObjChildElement.getName() =='MasteredIndicator'){
                                        masteredIndicator = conObjChildElement.getText();
                                    }
                                    if(conObjChildElement.getName() =='ContactMDMEID'){
                                        contactEID = conObjChildElement.getText();
                                    }
                                    if(conObjChildElement.getName() =='SourceSystem'){
                                        sourceSystem = conObjChildElement.getText();
                                    }
                                }
                                }
                            }
                            }
                        }
                    }
                }
            }
        }  
    }
        
                                               
     if(resultCode =='FATAL'){
         for(Dom.XMLNode child : rootNode.getChildElements()) {
            if(child.getName() == 'TxResponse'){
                for(Dom.XmlNode secondChildElement : child.getChildElements()){
                    if(secondChildElement.getName() == 'TxResult'){
                        for(Dom.XmlNode txResultElement : secondChildElement.getChildElements()){
                            if(txResultElement.getName() == 'DWLError'){
                               for(Dom.XmlNode errorElement : txResultElement.getChildElements()){ 
                                    if(errorElement.getName() == 'ErrorMessage'){
                                         errorMessage = errorElement.getText();
                                    }
                                    if(errorElement.getName() == 'Throwable'){
                                        errorDescription = errorElement.getText();
                                    }
                                } 
                            }
                        }
                    }
                }
            }
         }
     }                                          
    // System.debug(errorMessage);
    // System.debug(errorDescription);
    
     if(resultCode =='SUCCESS'){
         Contact con =[Select id,name,NS_Mastered_Contact_Indicator__c,NS_Contact_MDM_EID__c from Contact where id=:contactId];
         
         if(masteredIndicator =='Y'){
             con.NS_Mastered_Contact_Indicator__c = 'Mastered';
         }
         else{
             con.NS_Mastered_Contact_Indicator__c = 'Unmastered';
         }
         con.NS_Contact_MDM_EID__c = contactEID;
         //con.NSSource_System__c = sourceSystem;
         update con;
     }      
    if(resultCode =='FATAL'){
        Exception__c excep = new Exception__c();
        if(errorMessage.length()<80){
        excep.Name = errorMessage;
        }else{
            excep.Name=  errorMessage.substring(0, 79);
        } 
        excep.Class_Name__c = 'NS_GeneralContactCreateFormController';
        excep.Method_Name__c = 'sendContactRequest'; 
        if(errorDescription.length()<255){
            excep.Description__c = errorDescription;
        }else{
            excep.Description__c=  errorDescription.substring(0, 254);
        } 
        insert excep;
      }
      
    //Pre-ExceptionCatcher
    if(acc.RecordType.DeveloperName == 'NS_OnlineCustomerBusiness' || acc.RecordType.DeveloperName == 'NS_OnlineCustomerService')
         {
             if(String.isBlank(acc.AccountNumber))
             {
                 Exception__c excep = new Exception__c();
                 excep.Name = 'Account Number is blank';
                 excep.Class_Name__c = 'NS_GeneralContactEditFormController';
                 excep.Method_Name__c = 'sendContactRequest'; 
                 excep.Description__c = 'We cannot sent the contact to MDM if account number is blank';
                 insert excep;
             }
         }
         else if(acc.RecordType.DeveloperName == 'NS_OnlineCustomerCorporate'){
             if(String.isBlank(acc.NS_MDM_EID__c)){
                 Exception__c excep = new Exception__c();
                 excep.Name = 'MDM EID is blank';
                 excep.Class_Name__c = 'NS_GeneralContactEditFormController';
                 excep.Method_Name__c = 'sendContactRequest'; 
                 excep.Description__c = 'We cannot sent the contact to MDM if MDM EID is blank';
                 insert excep;
             }                                  
         }
        //End_Pre-ExceptionCatcher    
       }                                       
    return response;
    }
    
    @AuraEnabled
    public static String sendContactRequestWithMDMEid(Id contactId){
                                            
       String ENDPOINT_KEY ='ContactMDMEndpoint';
       String endpointMDM;                                     
       Map<String,NS_Integration_Endpoints__c> endpoints = NS_Integration_Endpoints__c.getAll();  
        if(endpoints.containsKey(ENDPOINT_KEY)){
            endpointMDM = endpoints.get(ENDPOINT_KEY).Endpoint_URL__c;
        }
                                            
    
        String response;
        String wPhnAreaCode;
        String wPhone; 
        String mPhnAreaCode;
        String mPhone; 
        String resultCode; 
        String masteredIndicator; 
        String contactEID;  
        String sourceSystem; 
        String errorMessage;
        String errorDescription;
       // List<string> identifierNumber=new List<string>();
        Datetime todaysdt = System.now();
        String date1 = String.valueOf(todaysdt.date());
        String time1 = String.valueOf(todaysdt.time());
        String year = date1.substring(0,4);
        String month = date1.substring(5,7);
        String day = date1.substring(8,10);
        String hour1 = time1.substring(0,2);
        String min1 = time1.substring(3,5);
        String sec1 = time1.substring(6,8);
        String requestId = year+month+day+hour1+min1+sec1;
        String body;
       // System.debug(requestId);
        
       contact c = [select id,FirstName,LastName,AccountId,NSSource_System__c,Phone,Email,MobilePhone,NS_Work_Phone_Ext__c,NS_PreferredName__c,NS_Contact_MDM_EID__c,NS_RACF_ID__c,NS_Mastered_Contact_Indicator__c,NS_AccessNS_Authorization_Status__c,Notification_SMS_Enabled__c,Notification_Email_Enabled__c from contact where id =: contactId Limit 01];
        
        User u = [SELECT FederationIdentifier FROM User where id =: userInfo.getUserId() Limit 01];
        Account acc = [SELECT id,AccountNumber,NS_MDM_EID__c,RecordType.DeveloperName from Account where id =:c.AccountId];
        
        String workPhone = c.Phone;
        String mobilePhone = c.MobilePhone;
         
        if(!String.isBlank(workPhone) && workPhone.startsWith('1')){
            wPhnAreaCode = workPhone.substring(1,4);
            wPhone = workPhone.substring(4);
        }
       else if(!String.isBlank(workPhone)){
            wPhnAreaCode = workPhone.substring(0,3);
            wPhone = workPhone.substring(3);
        }   
                                               
        if(!String.isBlank(mobilePhone) && mobilePhone.startsWith('1')){
            mPhnAreaCode = mobilePhone.substring(1,4);
            mPhone = mobilePhone.substring(4);
        }
       else if(!String.isBlank(mobilePhone)){
            mPhnAreaCode = mobilePhone.substring(0,3);
            mPhone = mobilePhone.substring(3);
        } 
     if(c.NS_Contact_MDM_EID__c != null && !c.NS_Contact_MDM_EID__c.toLowerCase().contains('old')) {                                     
            body ='<?xml version="1.0" encoding="UTF-8"?>';
            body+='<TCRMService xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ';
            body+='xmlns="http://www.ibm.com/mdm/schema" xsi:schemaLocation="http://www.ibm.com/mdm/schema MDMDomains.xsd">';
            body+='<RequestControl>';
            body+='<requestID>'+requestId+'</requestID>';//contact.id
            body+='<DWLControl>';
            body+='<requesterName>'+u.FederationIdentifier+'</requesterName>';//User.FederationIdentifier
            body+='<requesterLanguage>100</requesterLanguage>';
            body+='</DWLControl>';
            body+='</RequestControl>';
            body+='<TCRMTx>';
            body+='<TCRMTxType>maintainContactAndAccount</TCRMTxType>';
            body+='<TCRMTxObject>ContactAndAccountRequestBObj</TCRMTxObject>';
            body+='<TCRMObject>';
            body+='<ContactAndAccountRequestBObj>';
            body+='<ActionIndicator>Add</ActionIndicator>';
         if(acc.RecordType.DeveloperName == 'NS_OnlineCustomerCorporate'){                                    
            body+='<Relationship>Corporate Contact Association</Relationship>';
         }
         else if(acc.RecordType.DeveloperName == 'NS_OnlineCustomerBusiness' || acc.RecordType.DeveloperName == 'NS_OnlineCustomerService'){
             body+='<Relationship>Location Association</Relationship>';                                      
          }                                      
            body+='<SourceSystem>ConnectNS</SourceSystem>';
            body+='<StartDate></StartDate>';//TODAY()
            body+='<EndDate></EndDate>';
            body+='<ContactListBObj>';
            body+='<NSContactBObj>';
            body+='<ActionIndicator>Update</ActionIndicator>';
            body+='<FirstName>'+c.FirstName+'</FirstName>';//Contact.FirstName
            body+='<MiddleName></MiddleName>';
            body+='<LastName>'+c.LastName+'</LastName>';
            //body+='<PreferredName>'+c.NS_PreferredName__c+'</PreferredName>';
            if(String.isBlank(c.NS_PreferredName__c)){
                body+='<PreferredName></PreferredName>';
            }else{
                body+='<PreferredName>'+c.NS_PreferredName__c+'</PreferredName>';
            }
      
          //body+='<Email>'+c.Email+'</Email>';//Email
            if(!String.isBlank(c.Email)){
                body+='<Email>'+c.Email+'</Email>';
            }
          body+='<EmailNotificationIndicator>N</EmailNotificationIndicator>';
            body+='<MasteredIndicator>N</MasteredIndicator>';
            body+='<SourceSystem>ConnectNS</SourceSystem>';
            //body+='<SourceSystem>'+c.NSSource_System__c +'</SourceSystem>';
            body+='<WorkPhoneBObj>';
            if(!String.isBlank(workPhone)){                                    
              body+='<WorkPhoneNumber>'+workPhone+'</WorkPhoneNumber>';
              body+='<CountryCode>1</CountryCode>';
              body+='<AreaCode>'+wPhnAreaCode+'</AreaCode>';
              body+='<PhoneNumber>'+wPhone+'</PhoneNumber>';                
              //body+='<Extension>'+c.NS_Work_Phone_Ext__c+'</Extension>';
                if(String.isBlank(c.NS_Work_Phone_Ext__c)){
                    body+='<Extension></Extension>';
                }
                else{
                    body+='<Extension>'+c.NS_Work_Phone_Ext__c+'</Extension>'; 
                }
            }else{
                body+='<WorkPhoneNumber/>';
            }
            body+='</WorkPhoneBObj>';
            body+='<MobilePhoneBObj>';
            if(!String.isBlank(mobilePhone)){                                    
              body+='<MobilePhoneNumber>'+mobilePhone+'</MobilePhoneNumber>';
              body+='<CountryCode>1</CountryCode>';
              body+='<AreaCode>'+mPhnAreaCode+'</AreaCode>';
              body+='<PhoneNumber>'+mPhone+'</PhoneNumber>';                    
              body+='<MobileNotificationIndicator>N</MobileNotificationIndicator>';
            }else{
                body+='<MobilePhoneNumber/>';  
            }
            body+='</MobilePhoneBObj>';   
            body+='<NSIdentifierBObj>';
            body+='<Identifier>EID</Identifier>';
            body+='<IdentifierNumber>'+c.NS_Contact_MDM_EID__c+'</IdentifierNumber>';//Contact.Id
            body+='<StartDate></StartDate>';//TODAY()
            body+='<EndDate></EndDate>';
            body+='<IdentifierLastUpdateDate></IdentifierLastUpdateDate>';
            body+='<IdentifierLastUpdateUser></IdentifierLastUpdateUser>';
            body+='</NSIdentifierBObj>';
            body+='</NSContactBObj>';
            body+='</ContactListBObj>';
          if(acc.RecordType.DeveloperName == 'NS_OnlineCustomerBusiness' || acc.RecordType.DeveloperName == 'NS_OnlineCustomerService'){                                     
            body+='<Full10AccountListBObj>';
            body+='<Full10BObj>';
            body+='<AccountNumber>'+acc.AccountNumber+'</AccountNumber>';//Contact.Account.AccountNumber
            body+='</Full10BObj>';
            body+='</Full10AccountListBObj>';
          }
          if(acc.RecordType.DeveloperName == 'NS_OnlineCustomerCorporate'){                                      
            body+='<CorporateAccountListBObj>';
            body+='<CorporateAccountBObj>';
            body+='<CorporateMDMEID>'+acc.NS_MDM_EID__c+'</CorporateMDMEID>';//Contact.Account.NS_MDM_EID__c
            body+='</CorporateAccountBObj>';
            body+='</CorporateAccountListBObj>';
          }
            body+='</ContactAndAccountRequestBObj>';
            body+='</TCRMObject>';
            body+='</TCRMTx>';
            body+='</TCRMService>';                                            
           system.debug(body);
        } 
                                               
     //  String endpoint ='https://qaapi.nscorp.com/external/connectns-api/mdm';
        //SFCOE-3280 start : Added access token code
        NS_Oauth2 auth = new NS_Oauth2();
        HttpResponse hres;
        String accToken = auth.ReturnAccessToken(auth);
        if(accToken != null){
            if(body != null && body !=''){
                hres = NS_WSCallout.sendRequestRestWithOAUTH(endpointMDM, 'PUT', 'text/xml', accToken, body);
            }    
        }
        //HttpResponse hres = NS_WSCallout.sendRequestRest(endpointMDM, 'PUT','text/xml',body);
        //SFCOE-3280 end
        System.debug('Response ' + (hres != null ? hres.getBody() : 'null'));
    if (mdmResp != null && !String.isBlank(mdmResp.getBody())) {
    String xmlResponse = hres.getBody();
    DOM.Document doc=new DOM.Document();
      doc.load(xmlResponse);
      DOM.XmlNode rootNode=doc.getRootElement();
      
      for(Dom.XMLNode child : rootNode.getChildElements()) {
        //System.debug(child.getName()); 
      if(child.getName() == 'ResponseControl'){
        for(Dom.XmlNode childElement : child.getChildElements()){
        //System.debug(childElement.getName());
            if(childElement.getName() =='ResultCode'){
                resultCode = childElement.getText();
            }
           }
         }   
      }
     
    if(resultCode =='SUCCESS'){
        for(Dom.XMLNode child : rootNode.getChildElements()) {
            if(child.getName() == 'TxResponse'){
                for(Dom.XmlNode secondChildElement : child.getChildElements()){
                    if(secondChildElement.getName() =='ResponseObject'){
                        for(Dom.XmlNode resObjChildElement :secondChildElement.getChildElements()){
                           // system.debug(resObjChildElement.getName());
                            if(resObjChildElement.getName() =='ContactAndAccountResponseBObj'){
                                for(Dom.XmlNode conAccObjChildElement :resObjChildElement.getChildElements()){
                                    if(conAccObjChildElement.getName() =='ContactAndAccountBObj'){
                                for(Dom.XmlNode conObjChildElement :conAccObjChildElement.getChildElements()){
                                    if(conObjChildElement.getName() =='MasteredIndicator'){
                                        masteredIndicator = conObjChildElement.getText();
                                    }
                                    if(conObjChildElement.getName() =='ContactMDMEID'){
                                        contactEID = conObjChildElement.getText();
                                    }
                                    if(conObjChildElement.getName() =='SourceSystem'){
                                        sourceSystem = conObjChildElement.getText();
                                    }
                                }
                                }
                            }
                            }
                        }
                    }
                }
            }
        }  
    }
        
                                               
     if(resultCode =='FATAL'){
         for(Dom.XMLNode child : rootNode.getChildElements()) {
            if(child.getName() == 'TxResponse'){
                for(Dom.XmlNode secondChildElement : child.getChildElements()){
                    if(secondChildElement.getName() == 'TxResult'){
                        for(Dom.XmlNode txResultElement : secondChildElement.getChildElements()){
                            if(txResultElement.getName() == 'DWLError'){
                               for(Dom.XmlNode errorElement : txResultElement.getChildElements()){ 
                                    if(errorElement.getName() == 'ErrorMessage'){
                                         errorMessage = errorElement.getText();
                                    }
                                    if(errorElement.getName() == 'Throwable'){
                                        errorDescription = errorElement.getText();
                                    }
                                } 
                            }
                        }
                    }
                }
            }
         }
     }                                          
    // System.debug(errorMessage);
    // System.debug(errorDescription);
    
     if(resultCode =='SUCCESS'){
         Contact con =[Select id,name,NS_Mastered_Contact_Indicator__c,NS_Contact_MDM_EID__c from Contact where id=:contactId];
         
         if(masteredIndicator =='Y'){
             con.NS_Mastered_Contact_Indicator__c = 'Mastered';
         }
         else{
             con.NS_Mastered_Contact_Indicator__c = 'Unmastered';
         }
         con.NS_Contact_MDM_EID__c = contactEID;
         //con.NSSource_System__c = sourceSystem;
         update con;
     }      
    if(resultCode =='FATAL'){
        Exception__c excep = new Exception__c();
        if(errorMessage.length()<80){
        excep.Name = errorMessage;
        }else{
            excep.Name=  errorMessage.substring(0, 79);
        } 
        excep.Class_Name__c = 'NS_GeneralContactCreateFormController';
        excep.Method_Name__c = 'sendContactRequest'; 
        if(errorDescription.length()<255){
            excep.Description__c = errorDescription;
        }else{
            excep.Description__c=  errorDescription.substring(0, 254);
        } 
        insert excep;
      }
      
    //Pre-ExceptionCatcher
    if(acc.RecordType.DeveloperName == 'NS_OnlineCustomerBusiness' || acc.RecordType.DeveloperName == 'NS_OnlineCustomerService')
         {
             if(String.isBlank(acc.AccountNumber))
             {
                 Exception__c excep = new Exception__c();
                 excep.Name = 'Account Number is blank';
                 excep.Class_Name__c = 'NS_GeneralContactEditFormController';
                 excep.Method_Name__c = 'sendContactRequest'; 
                 excep.Description__c = 'We cannot sent the contact to MDM if account number is blank';
                 insert excep;
             }
         }
         else if(acc.RecordType.DeveloperName == 'NS_OnlineCustomerCorporate'){
             if(String.isBlank(acc.NS_MDM_EID__c)){
                 Exception__c excep = new Exception__c();
                 excep.Name = 'MDM EID is blank';
                 excep.Class_Name__c = 'NS_GeneralContactEditFormController';
                 excep.Method_Name__c = 'sendContactRequest'; 
                 excep.Description__c = 'We cannot sent the contact to MDM if MDM EID is blank';
                 insert excep;
             }                                  
         }
        //End_Pre-ExceptionCatcher    
    }                                         
    return response;
    }
}