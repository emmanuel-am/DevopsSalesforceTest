// childComponent.js
import { LightningElement, api, track } from 'lwc';

export default class ChildComponentExercise extends LightningElement {
    @api contactData;
    @api contactList;
    @api statistics;
    @api filterConfig;
    
    @track internalData = { 
        timestamp: null, 
        processed: false,
        statusHistory: [],
        analysisData: {}
    };

    connectedCallback() {
        this.updateTimestamp();
        this.performAnalysis();
    }

    get hasContactData() {
        return this.contactData && this.contactData.contact && this.contactData.contact.Name;
    }

    get processedContact() {
        if (!this.contactData) return null;
        
        // Usando spread operator para procesar datos complejos
        const baseContact = { ...this.contactData.contact };
        const wrapperData = { ...this.contactData };
        
        return {
            ...baseContact,
            ...wrapperData,
            displayName: `${this.getContactIcon(wrapperData)} ${baseContact.Name}`,
            formattedAmount: this.formatCurrency(wrapperData.totalAmount),
            riskLevel: this.calculateRiskLevel(wrapperData),
            scoreData: this.calculateContactScore(wrapperData),
            enhancedTags: [...wrapperData.tags, ...this.generateDynamicTags(wrapperData)]
        };
    }

    get totalContacts() {
        return this.contactList ? this.contactList.length : 0;
    }

    get analysisResults() {
        if (!this.contactList || this.contactList.length === 0) return null;
        
        const analysis = { ...this.internalData.analysisData };
        
        // Análisis con spread operator
        const amounts = this.contactList.map(c => c.totalAmount);
        const opportunities = this.contactList.map(c => c.totalOpportunities);
        
        return {
            ...analysis,
            avgAmount: amounts.reduce((a, b) => a + b, 0) / amounts.length,
            maxAmount: Math.max(...amounts),
            minAmount: Math.min(...amounts),
            avgOpportunities: opportunities.reduce((a, b) => a + b, 0) / opportunities.length,
            highValueContacts: this.contactList.filter(c => c.totalAmount > 25000).length,
            activeContacts: this.contactList.filter(c => c.hasRecentActivity).length
        };
    }

    get chartData() {
        if (!this.statistics || !this.statistics.typeBreakdown) return [];
        
        return this.statistics.typeBreakdown.map(item => ({
            ...item,
            percentage: ((item.count / this.statistics.totalContacts) * 100).toFixed(1)
        }));
    }

    @api
    refreshData() {
        this.updateTimestamp();
        this.performAnalysis();
        this.internalData = { 
            ...this.internalData, 
            processed: true,
            lastRefresh: new Date().toISOString()
        };
        
        // Usando querySelector para actualizar elementos
        const statusElement = this.template.querySelector('.status-indicator');
        const analysisElement = this.template.querySelector('.analysis-container');
        
        if (statusElement) {
            statusElement.classList.add('slds-theme_success');
            setTimeout(() => {
                statusElement.classList.remove('slds-theme_success');
            }, 2000);
        }
        
        if (analysisElement) {
            analysisElement.style.transform = 'scale(1.02)';
            setTimeout(() => {
                analysisElement.style.transform = 'scale(1)';
            }, 300);
        }
    }

    @api
    handleStatusUpdate(status) {
        const newStatusEntry = {
            status,
            timestamp: new Date().toLocaleTimeString(),
            contactId: this.contactData?.contact?.Id
        };
        
        this.internalData = {
            ...this.internalData,
            statusHistory: [...this.internalData.statusHistory, newStatusEntry]
        };
    }

    updateTimestamp() {
        this.internalData = { 
            ...this.internalData, 
            timestamp: new Date().toLocaleTimeString() 
        };
    }

    performAnalysis() {
        if (!this.contactList || this.contactList.length === 0) return;
        
        const analysisData = {
            totalRevenue: this.contactList.reduce((sum, c) => sum + c.totalAmount, 0),
            avgScore: this.contactList.reduce((sum, c) => sum + this.calculateContactScore(c).total, 0) / this.contactList.length,
            riskDistribution: this.getRiskDistribution(),
            topPerformers: this.getTopPerformers()
        };
        
        this.internalData = {
            ...this.internalData,
            analysisData: { ...analysisData }
        };
    }

    calculateContactScore(contactWrapper) {
        const revenueScore = Math.min(contactWrapper.totalAmount / 1000, 50);
        const opportunityScore = Math.min(contactWrapper.totalOpportunities * 5, 30);
        const activityScore = contactWrapper.hasRecentActivity ? 20 : 0;
        const total = revenueScore + opportunityScore + activityScore;
        
        return {
            revenue: Math.round(revenueScore),
            opportunity: Math.round(opportunityScore),
            activity: activityScore,
            total: Math.round(total)
        };
    }

    calculateRiskLevel(contactWrapper) {
        const score = this.calculateContactScore(contactWrapper).total;
        if (score >= 70) return { level: 'Low', color: 'slds-theme_success' };
        if (score >= 40) return { level: 'Medium', color: 'slds-theme_warning' };
        return { level: 'High', color: 'slds-theme_error' };
    }

    getContactIcon(contactWrapper) {
        if (contactWrapper.totalAmount > 50000) return '⭐';
        if (contactWrapper.hasRecentActivity) return '🔥';
        if (contactWrapper.totalOpportunities > 3) return '🎯';
        return '👤';
    }

    generateDynamicTags(contactWrapper) {
        const dynamicTags = [];
        const score = this.calculateContactScore(contactWrapper).total;
        
        if (score >= 70) dynamicTags.push('Top Performer');
        if (contactWrapper.totalAmount > 0 && contactWrapper.totalOpportunities === 0) dynamicTags.push('Revenue Only');
        if (contactWrapper.accountType === 'Enterprise') dynamicTags.push('Enterprise');
        
        return dynamicTags;
    }

    getRiskDistribution() {
        const distribution = { Low: 0, Medium: 0, High: 0 };
        this.contactList.forEach(contact => {
            const risk = this.calculateRiskLevel(contact).level;
            distribution[risk]++;
        });
        return distribution;
    }

    getTopPerformers() {
        return this.contactList
            .map(contact => ({
                name: contact.contact.Name,
                score: this.calculateContactScore(contact).total
            }))
            .sort((a, b) => b.score - a.score)
            .slice(0, 3);
    }

    formatCurrency(amount) {
        return new Intl.NumberFormat('es-MX', {
            style: 'currency',
            currency: 'MXN',
            minimumFractionDigits: 0
        }).format(amount);
    }
}