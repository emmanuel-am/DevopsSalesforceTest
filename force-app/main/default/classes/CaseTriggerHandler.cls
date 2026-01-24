public with sharing class CaseTriggerHandler {
    public static void handleAfterInsert(List<Case> newRecords) {
        //Prevenir tu trigger call, usamos system.isfuture que dice si este eapex classs method ha sido llamado debido a un metodo futuro 
        //Si cualquiera de estos sucede no necesitamos hacer el callout, retornamos el codigo desde aqui con el return
        if(System.isFuture() || System.isBatch()){
             return;
        }
        //Tenemos multiples casos hacemos el for loop
        for(Case c : newRecords){ // make a SQOL Query to get the Contact Details, porque en trigger.new no consigues el parent record information
            API_Basic_Authentication_ZendeskTicket.TicektWrapper wrapper = new API_Basic_Authentication_ZendeskTicket.TicektWrapper();
            wrapper.body = c.Description;
            wrapper.subject = c.Subject;
            wrapper.priority = c.Priority.toLowerCase(); // Allowed values are "urgent", "high", "normal", or "low".
            wrapper.name = 'Amit Singh';
            wrapper.email = 'asingh@example.org';
            //Todos son dinamicos menos name y email son estaticos
            // Converting the Object into String
            makeCallout( JSON.serialize(wrapper) );
        }
    }
    //Usamos otro metodo privado porque cual acepta el ticket wrapper class es porque el metodo futuro no puede aceptar la lista de records, no puedes pasar lista de objects en el metodo futuro
    //Future method es asincrono process y es una forma de ejecutar una pieza de codigo en un futuro cercano cuando salesforce recursos son free
    //Si no quieres hacer el callout usando metodo desde un trigger tenemos queueable y batch apex en trigger pero debes tener en cuenta los limites de asincronos process igual para future
    //Future Method salesforce decide cuando el metodo futuro va a ser ejecutado cuando tiene recursos
    //Podemos solo añadir 50 metodos futuros en un transaccion unica 
    //No es recomendado hacer bulk call outs desde apex triggers, segundo no soporta el bulk call out from apex triggers, puedes intenar con queueable pero tambien es time consuming y el mantenimiento es alto 
    //cuando crees casos de bulk con data loader o tools como mulesoft es recomendable desabilitar tu callout usando alguna configuracion y usar batch apex para hacer el callout es la mejor solucion para multiples records callouts
    //si hay multiples records creados usa batch apex para enviar estos detalles al external system en 25 minutos o dentro de dias 
    @future(callout = true) // THIS is not the best Solution, si hay multiples registros es mejor usar batch apex, esa es la approach a seguir para bulkfication de este callouts desde apex trigger
    private static void makeCallout(String params){
        // Convert the String in object(class)
        API_Basic_Authentication_ZendeskTicket.TicektWrapper wrapper = (API_Basic_Authentication_ZendeskTicket.TicektWrapper)JSON.deserialize(params, API_Basic_Authentication_ZendeskTicket.TicektWrapper.class); //retorna un objeto y hacemos el casteo a object
        API_Basic_Authentication_ZendeskTicket.createTicket(wrapper);
    }    
}

//Si el cliente no tiene problemas de dinero puedes usar un middleware para hacer los api calls y conseguir el sistema actualizado
//tan pronto el caso es creado el middleware se mantiene escuchando por la creacion de eventos de caso y ellos hacen el api call por ti, consiguen los detalles la transformacion, ya sea con plaform event o update the case 
// pero si no tiene dinero y va a crear miles de records en un single bulk upload para cases no puedes usar apex triggers porque tienes que pensar en los limites, batch es una solucion pero hay un detalle coore en batches de 200 records a la vez y tu puedes solo 100 entradas en la flex queue
//tan pronto consigas mas de 2000 records en un solo trigger tu fle queue esta llena  puedes poner queueable or future pero aun hay prblem la solucion es un middleware or un batch apex for callout o un custom framework para implemenatr esta flex queue pero esto es muy complicado 
//puede programar un bacth apex que corra cada 30 horas y todme los casos creados en los ultimos 30 minutos y los envie al third party sistema y conseguir el id
//otra solucion es override the case creation process en lugar de usar la standard UI para crear casos usar una custom UI con la ayuda de lighning aura a la hora de salvar el record  tu puedes hacer un real time callout  conseguir la informacion y salvarla pero si son mucho no lo puedes conotrlar
//Se escoge la mejor solucion para bussines 