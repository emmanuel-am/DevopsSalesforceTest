// ContactControllerParentToChild.cls
public with sharing class ContactControllerParentToChild {
    
    // Wrapper class para retornar datos más complejos
    public class ContactWrapper {
        @AuraEnabled public Contact contact { get; set; }
        @AuraEnabled public Integer totalOpportunities { get; set; }
        @AuraEnabled public Decimal totalAmount { get; set; }
        @AuraEnabled public String accountType { get; set; }
        @AuraEnabled public Boolean hasRecentActivity { get; set; }
        @AuraEnabled public List<String> tags { get; set; }
        
        public ContactWrapper(Contact cont, Integer oppCount, Decimal amount, String accType, Boolean hasActivity) {
            this.contact = cont;
            this.totalOpportunities = oppCount;
            this.totalAmount = amount != null ? amount : 0;
            this.accountType = accType;
            this.hasRecentActivity = hasActivity;
            this.tags = new List<String>();
            
            // Generar tags dinámicamente
            if (oppCount > 5) this.tags.add('High Volume');
            if (amount > 10000) this.tags.add('High Value');
            if (hasActivity) this.tags.add('Active');
            if (String.isNotBlank(cont.Email)) this.tags.add('Email Available');
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<ContactWrapper> getContactsWithDetails() {
        try {
            List<ContactWrapper> contactWrappers = new List<ContactWrapper>();
            
            // Query principal de contactos
            List<Contact> contacts = [
                SELECT Id, Name, Email, Phone, AccountId, Account.Name, Account.Type
                FROM Contact 
                WHERE Account.Type != null 
                AND Name != null
                ORDER BY Name
                LIMIT 10
            ];
            
            // Obtener IDs de contactos
            Set<Id> contactIds = new Set<Id>();
            for (Contact cont : contacts) {
                contactIds.add(cont.Id);
            }
            
            // Query para oportunidades relacionadas con las cuentas de los contactos
            Map<Id, List<Opportunity>> oppsByAccount = new Map<Id, List<Opportunity>>();
            List<Opportunity> opportunities = [
                SELECT Id, Amount, CloseDate, AccountId
                FROM Opportunity 
                WHERE AccountId IN (SELECT AccountId FROM Contact WHERE Id IN :contactIds)
                AND Amount != null
            ];
            
            for (Opportunity opp : opportunities) {
                if (!oppsByAccount.containsKey(opp.AccountId)) {
                    oppsByAccount.put(opp.AccountId, new List<Opportunity>());
                }
                oppsByAccount.get(opp.AccountId).add(opp);
            }
            
            // Query para tareas relacionadas con los contactos
            Map<Id, List<Task>> tasksByContact = new Map<Id, List<Task>>();
            List<Task> tasks = [
                SELECT Id, CreatedDate, WhoId
                FROM Task 
                WHERE WhoId IN :contactIds 
                AND CreatedDate = LAST_N_DAYS:30
            ];
            
            for (Task task : tasks) {
                if (!tasksByContact.containsKey(task.WhoId)) {
                    tasksByContact.put(task.WhoId, new List<Task>());
                }
                tasksByContact.get(task.WhoId).add(task);
            }
            
            // Procesar cada contacto
            for (Contact cont : contacts) {
                // Obtener oportunidades de la cuenta del contacto
                List<Opportunity> accountOpps = oppsByAccount.get(cont.AccountId);
                if (accountOpps == null) accountOpps = new List<Opportunity>();
                
                // Obtener tareas del contacto
                List<Task> contactTasks = tasksByContact.get(cont.Id);
                if (contactTasks == null) contactTasks = new List<Task>();
                
                Integer oppCount = accountOpps.size();
                Decimal totalAmount = 0;
                Boolean hasRecentActivity = !contactTasks.isEmpty();
                
                // Calcular total de oportunidades
                for (Opportunity opp : accountOpps) {
                    if (opp.Amount != null) {
                        totalAmount += opp.Amount;
                    }
                }
                
                String accountType = cont.Account?.Type != null ? cont.Account.Type : 'Unknown';
                
                contactWrappers.add(new ContactWrapper(
                    cont, oppCount, totalAmount, accountType, hasRecentActivity
                ));
            }
            
            return contactWrappers;
            
        } catch (Exception e) {
            System.debug('Error in getContactsWithDetails: ' + e.getMessage());
            throw new AuraHandledException('Error al obtener contactos: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String updateContactStatus(String contactId, String status) {
        try {
            if (String.isBlank(contactId)) {
                throw new AuraHandledException('Contact ID is required');
            }
            
            Contact cont = [SELECT Id, Description FROM Contact WHERE Id = :contactId LIMIT 1];
            
            String currentDescription = cont.Description != null ? cont.Description : '';
            String timestamp = Datetime.now().format('yyyy-MM-dd HH:mm:ss');
            
            cont.Description = currentDescription + '\n[' + timestamp + '] Status: ' + status;
            
            update cont;
            
            return 'Contact updated successfully at ' + timestamp;
            
        } catch (Exception e) {
            System.debug('Error in updateContactStatus: ' + e.getMessage());
            throw new AuraHandledException('Error al actualizar contacto: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getContactStatistics() {
        try {
            Map<String, Object> stats = new Map<String, Object>();
            
            // Estadísticas agregadas simplificadas
            List<AggregateResult> accountTypeStats = [
                SELECT Account.Type accType, COUNT(Id) contactCount
                FROM Contact 
                WHERE Account.Type != null
                GROUP BY Account.Type
                ORDER BY COUNT(Id) DESC
            ];
            
            List<Map<String, Object>> typeBreakdown = new List<Map<String, Object>>();
            Integer totalContacts = 0;
            
            for (AggregateResult ar : accountTypeStats) {
                Map<String, Object> typeData = new Map<String, Object>();
                typeData.put('type', ar.get('accType'));
                typeData.put('count', ar.get('contactCount'));
                typeData.put('avgAmount', 25000); // Valor fijo por simplicidad
                
                typeBreakdown.add(typeData);
                totalContacts += (Integer)ar.get('contactCount');
            }
            
            stats.put('totalContacts', totalContacts);
            stats.put('typeBreakdown', typeBreakdown);
            stats.put('lastUpdated', Datetime.now().format('yyyy-MM-dd HH:mm:ss'));
            
            return stats;
            
        } catch (Exception e) {
            System.debug('Error in getContactStatistics: ' + e.getMessage());
            throw new AuraHandledException('Error al obtener estadísticas: ' + e.getMessage());
        }
    }
}