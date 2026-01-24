import { LightningElement } from 'lwc';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';

export default class Ps_batchapexerrorevent extends LightningElement {
    subscription;
    eventName = '/event/SAP_Account__e';
    eventMessage;

    connectedCallback(){
        this.reisterErrorHandler();
        this.handleSubscribe(); //al cargar el componente te subscribes a un evento
    }
   //-2 seria si quieres que responda todos los eventos y -1 solo responda los eventos nuevos
    handleSubscribe(){
        //no puedes asignar el valor que consigues como message  de tu platform event en una variable
        // para resolverlo creamos handleSuccessErrorMessage, bind metodo retorna la nueva instancia del metodo que estas binding
        this.subscription = subscribe(this.eventName, -2, this.handleSuccessErrorMessage.bind(this)); //tercer parametro es la funcion que se ejecuta cuando un evento es recibido
        console.log(this.subscription);
    }

    handleSuccessErrorMessage(message){
       console.log('Message Received!');
       this.eventMessage = JSON.stringify(message);
    }

    disconnectedCallback(){
       this.handleUnSubscribe();
    }

    handleUnSubscribe(){
       unsubscribe(this.subscription, (response) => {
           console.log(response);
       });
    }

    reisterErrorHandler(){
       onError((error) => {
           console.error(error);
       });
    } 
}
