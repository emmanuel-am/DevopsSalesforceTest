import { api, LightningElement, wire } from 'lwc';
import uploadedFile from '@salesforce/apex/DropboxFileManagerHandler.uploadFile';

import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import NAME_FIELD from "@salesforce/schema/Opportunity.Name";

import { ShowToastEvent } from 'lightning/platformShowToastEvent';



export default class DropboxFileManager extends LightningElement {

    @api recordId;
    @api objectApiName;
    isLoading = false;

    connectedCallback(){
        console.log('Name field ', JSON.stringify(NAME_FIELD));
    }

    @wire(getRecord, {
        recordId: "$recordId",
        fields: [NAME_FIELD],
    })
    record;

    get name(){
        return getFieldValue(this.record.data, NAME_FIELD);
    }

    handleUploadFinished(event){
        const uploadedFiles = event.detail.files;
        console.log(uploadedFiles);
        for(let i=0; i<uploadedFiles.length; i++){
            const file = uploadedFiles[i];
            this.isLoading = true;
            this.handleFileUpload(file.contentVersionId);
        }
    }
    handleFileUpload(fileId){
        uploadedFile({
            fileId: fileId,
            filePath: this.name,
            recordId: this.recordId
        })
        .then(result =>{
            console.log('Result', result);
            this.dispatchEvent(new ShowToastEvent({
                title: "Success",
                message: "File uploaded successfully",
                variant: "success"
            }));
        })
        .catch(error =>{
            console.log('Error', error);
            this.dispatchEvent(new ShowToastEvent({
                title: "Error",
                message: "Error while uploading file "+JSON.stringify(error),
                variant: "error"
            }));
        })
        .finally(()=>{
            this.isLoading = false;
        })

    }
}