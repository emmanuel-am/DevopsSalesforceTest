public with sharing class API_Key_Authentication_OpenCageGeoCoder { 
    //Apex clas va a aceptar el accountId como parametro, vamos a query latitud y longitud luego hare el api call y luego voy a actualizar de vuelta el account record 
    public static void API_Key_Authentication_OpenCageGeoCoder(String accountId) {//argument
         /* Step 0 - Get the lattitude and longitude for given account */
         Account accRecord = [SELECT Id, Location__Latitude__s, Location__Longitude__s
                              FROM 
                                    Account 
                              WHERE 
                                    Id =: accountId
                                    AND Location__Latitude__s != null
                                    AND Location__Longitude__s != null 
                              LIMIT 1 
                            ];
        /*Step 0.1 - Prepare the Query Params */
        String queryParams = accRecord.Location__Latitude__s + ',' + accRecord.Location__Longitude__s; //As per api document
        System.debug(queryParams);

        // URLEncode of that complete Query parameter
        // EncodingUtil.urlEncode();

        /*Callouts Only */
        /*Step 1 - Prepare the request */
        HttpRequest httpReq = new HttpRequest();
        /* Step 1.1 - Send the endpoint */
        httpReq.setEndpoint(System.Label.OPENCAGE_API_URL+'?key='+
            System.Label.OPENCAGE_API_KEY+'&q='+queryParams+'&pretty=1');
        /* Step1.2 - Set the Headers */
        httpReq.setHeader('Content-Type', 'application/json');
        httpReq.setHeader('Accept', 'application/json');
        /* Step1.3 - Set the Method */
        httpReq.setMethod('GET'); //GET, POST, PUT, PATCH, DELETE
        /* Step 2 - Send the Request */
        Http http = new Http();
        try{
            HttpResponse httpResp = http.send(httpReq);
            /* Step 3 - Print the information */
            /*
            getStatus()
            getStatusCode()
            getBody()
            getXmlStreamReader() ---> SOAP
            getBodyAsBlob()
        */
            String responseBody = httpResp.getBody(); //retorna String
            Integer statusCode = httpResp.getStatusCode();
            //GET, 200
            if(statusCode == 200){
                // main logic
                //convertir el string de body en nuestra clase
                // JSON Class inside System Namespace
                // deserialize, deserializeUnTyped, deserializeStrict
                //deserialize si tu tienes un string en forma de JSON tu puedes convertir esa string en cualquier custom standard object or custom o standard apex class
                //Object obj = System.JSON.deserialize(responseBody, OpenCageReverseResponseWrapper.class);
                //obj.results; no puedes hace esto porque no hay variable llamada result in esta clase object tienes que convertirla un object es el padre  y OpenCageReverseResponseWrapper es el child tienes que typecast de padre a hijo esto es dentro de () si la data no es la misma tu tienes que typecast, para que se asigne el valor a la variable de la derecja el tipo de ambos tiene que ser el mismo
                //Realizamos la deserializaciony la string que le damos en este caso el responsebody, lo convierte en esta class de opencagereverseresponsewrapper y cualquiera sea eñ resultado que nos da lo almacena en el object de la clase opencagereverseresponsewrapper con nombre de variable wrapper, el tipo de retorno es object del metodo deserilize y el de la variable wrapper es class no matchan para eso se hace el type casting de convertir el object en cualquier cosa en este caso la clase  
                OpenCageReverseResponseWrapper wrapper = (OpenCageReverseResponseWrapper) System.JSON.deserialize(responseBody, OpenCageReverseResponseWrapper.class); //el primer parametro de desearlize es el string que quieres convertir, el segundo es el tipo de dato class name, object name al que quieres convertir,  el tipo de retorno de deserialize method es un object
                //Type casting es cuando tienes una super class o super interface y quieres conseguir lo que esta abajo de eso y seras capaz de typecast
                //Cada standard class o custom class, standard object o custom object tiene que tener .class al final del parametro de la clase en el metodo de serialize, incluso si usas account tiene que tener .class detras de escena todo es una class
                //object es la parent class, es una super class puede contener todo un object, list, boolean o cualquier cosa
                //Si hay algo en wrapper ve y checa en results luego si hay algo en results  no es nulo ve y checa por size
                if(wrapper?.results?.size() > 0){
                //Lo de arriba es lo mismo que esto de abajo usamos los 2 ? porque quiere decir hay 2 condiciones antes de checar el size
                //if(wrapper != null && wrapper.results != null && wrapper.results.size()>0){}
                //si el valor es nulo no puedes usar is empty te lanzara null pointer exception, isEmpty no checa por null value
                //if(wrapper.results.isEmpty()){} 
                // si wrapper.results es null dira null.isempty dara null pointer exception porque no puedes realizar operaciones en null, no puedes poner isEmpty hasta que tu sabes que tu string  va a retornar al menos algo on un string vacio
                // The Compiler
                // The Run Time Environment ( Machine )
                    // wrapper?.results?.size() > 0  //es la representacion de un if con multiple condiciones donde dice si wrapper is not null and result no null y size mas grande que 0
                    // if wrapper is not null
                         // Yes -
                            // wrapper.results is not null
                                  // YES -
                                     // wrapper.results.size()
                                          // YES
                                          //Si la respuesta a esto es NO nada sucede, el codigo no se ejecuta, si es YES se jecuta el siguiente numero de lineas
                                          //nada en el if block sera ejecutado si el wrapper es nulo
                    OpenCageReverseResponseWrapper.results rslt = wrapper.results.get(0);
                    // Update Account Record
                    accRecord.BillingStreet = rslt?.components?.road; //con los ? checa si no hay nada en rslt esta bien almacena eso, pero si hay algo en results checa por components si no hay nada en components esta bien si todo esta ahi road va a ser almacenado en billingstreet
                    accRecord.BillingCity = rslt?.components?.city;
                    accRecord.BillingState = rslt?.components?.state;
                    accRecord.BillingPostalCode = rslt?.components?.postcode;
                    accRecord.BillingCountry = rslt?.components?.country;
                    accRecord.ShippingStreet = rslt?.components?.road;
                    accRecord.ShippingCity = rslt?.components?.city;
                    accRecord.ShippingState = rslt?.components?.state;
                    accRecord.ShippingPostalCode = rslt?.components?.postcode;
                    accRecord.ShippingCountry = rslt?.components?.country;
                    update accRecord;
                }
            }else{
                // error handling code...
            }
        }catch(System.CalloutException calloutEx){
            System.debug('System.CalloutException.... '+ calloutEx.getStackTraceString());
            if(String.valueOf(calloutEx).startsWith('System.CalloutException: Unauthorized endpoint')){
                //Remote Site missing Error
                System.debug('CalloutException ...');
            }
        }catch(System.Exception ex){
            System.debug('Exception Executed ...'+ex.getStackTraceString());
            if(String.valueOf(ex).startsWith('System.CalloutException: Unauthorized endpoint')){
                //Remote Site missing Error
                System.debug('Executed ...');
            }
        }

    }
}