// parentComponent.js
import { LightningElement, wire, track } from 'lwc';
import getContactsWithDetails from '@salesforce/apex/ContactControllerParentToChild.getContactsWithDetails';
import getContactStatistics from '@salesforce/apex/ContactControllerParentToChild.getContactStatistics';
import updateContactStatus from '@salesforce/apex/ContactControllerParentToChild.updateContactStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ParentComponentExercise extends LightningElement {
    @track contacts = [];
    @track statistics = {};
    @track selectedContact = null;
    @track isLoading = false;
    
    // Configuración con spread operator
    @track filterConfig = {
        showHighValue: false,
        showActive: false,
        accountType: 'All',
        ...{minOpportunities: 0} // Usando spread para merge
    };

    @wire(getContactsWithDetails)
    wiredContacts({ error, data }) {
        if (data) {
            this.contacts = data.map(wrapper => ({
                ...wrapper,
                contact: { ...wrapper.contact },
                formattedAmount: this.formatCurrency(wrapper.totalAmount),
                statusClass: this.getStatusClass(wrapper)
            }));
        } else if (error) {
            console.error('Error:', error);
            this.showToast('Error', 'Error al cargar contactos', 'error');
        }
    }

    @wire(getContactStatistics)
    wiredStats({ error, data }) {
        if (data) {
            this.statistics = { ...data };
        } else if (error) {
            console.error('Stats Error:', error);
        }
    }

    get filteredContacts() {
        return this.contacts.filter(contactWrapper => {
            const { showHighValue, showActive, accountType, minOpportunities } = this.filterConfig;
            
            if (showHighValue && contactWrapper.totalAmount < 10000) return false;
            if (showActive && !contactWrapper.hasRecentActivity) return false;
            if (accountType !== 'All' && contactWrapper.accountType !== accountType) return false;
            if (contactWrapper.totalOpportunities < minOpportunities) return false;
            
            return true;
        });
    }

    get accountTypes() {
        const types = [...new Set(this.contacts.map(c => c.accountType))];
        return [{ label: 'All', value: 'All' }, ...types.map(type => ({ label: type, value: type }))];
    }

    handleContactSelect(event) {
        const contactId = event.target.dataset.id;
        // Usando spread operator para crear copia profunda
        const selectedWrapper = this.contacts.find(c => c.contact.Id === contactId);
        this.selectedContact = selectedWrapper ? {
            ...selectedWrapper,
            contact: { ...selectedWrapper.contact },
            tags: [...selectedWrapper.tags]
        } : null;
    }

    handleFilterChange(event) {
        const { name, value, checked, type } = event.target;
        this.filterConfig = {
            ...this.filterConfig,
            [name]: type === 'checkbox' ? checked : value
        };
    }

    async handleUpdateStatus(event) {
        const contactId = event.target.dataset.id;
        const status = event.target.dataset.status;
        
        this.isLoading = true;
        
        try {
            const result = await updateContactStatus({ contactId, status });
            this.showToast('Success', result, 'success');
            
            // Actualizar el componente hijo
            const childComponent = this.template.querySelector('c-child-component');
            if (childComponent) {
                childComponent.handleStatusUpdate(status);
            }
            
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Error al actualizar', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleRefresh() {
        // Usando querySelector para acceder al componente hijo
        const childComponent = this.template.querySelector('c-child-component');
        if (childComponent) {
            childComponent.refreshData();
        }
    }

    formatCurrency(amount) {
        return new Intl.NumberFormat('es-MX', {
            style: 'currency',
            currency: 'MXN'
        }).format(amount);
    }

    getStatusClass(contactWrapper) {
        if (contactWrapper.totalAmount > 50000) return 'slds-theme_success';
        if (contactWrapper.hasRecentActivity) return 'slds-theme_warning';
        return 'slds-theme_default';
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({ title, message, variant });
        this.dispatchEvent(event);
    }
}