# Finmate - Personal Finance Management App

![Finmate Logo](assets/icons/LOGO.png)

## Overview

Finmate is a comprehensive personal finance management application built with Flutter that helps users track expenses, manage budgets, handle group finances, and gain insights into their spending habits. The app provides a clean, intuitive interface for managing various financial accounts while offering powerful analytical tools to make informed financial decisions.

## Features

### Transaction Management

- **Track Expenses & Income**: Log transactions with detailed categorization
- **Transfer Funds**: Move money between accounts and groups with ease
- **Transaction History**: View and filter past transactions
- **Multi-category Support**: Categorize transactions for better organization
- **Search & Filtering**: Find transactions by date, category, amount, or payment method

### Account Management

- **Multiple Bank Accounts**: Add and manage multiple bank accounts
- **Cash Management**: Track cash on hand
- **Balance Adjustments**: Make corrections to account balances as needed
- **UPI Integration**: Link UPI IDs to bank accounts for quick payments

### Group Finance

- **Shared Expenses**: Create groups for shared expenses with friends, family, or roommates
- **Member Balance Tracking**: Automatically calculate each member's balance
- **Group Transactions**: Record expenses within groups
- **Bank Account Linking**: Connect groups to bank accounts for seamless fund transfers
- **Group Chat**: Communicate with group members within the app

### Budget Management

- **Monthly Budgets**: Set monthly spending limits
- **Category Budgets**: Allocate budgets to specific expense categories
- **Budget Tracking**: Monitor spending against budgets
- **Budget Analytics**: View visual representations of budget utilization

### Analytics & Insights

- **Spending Patterns**: Visualize spending trends across categories
- **Monthly Analysis**: Track financial activity month-by-month
- **Interactive Charts**: Pie charts and radial bar charts for clear data visualization
- **Income vs. Expense**: Compare income and expenses over time

### Authentication & Security

- **Email/Password Authentication**: Secure account access
- **Google Sign-In**: Quick login with Google accounts
- **Profile Management**: Update user information and preferences

## Technology Stack

- **Frontend**: Flutter for cross-platform mobile development
- **State Management**: Riverpod for efficient and maintainable state management
- **Backend**: Firebase for authentication, database, and storage
- **Database**: Cloud Firestore for real-time data synchronization
- **Authentication**: Firebase Authentication for secure user management
- **Storage**: Firebase Storage for profile pictures and group images
- **Analytics**: Custom analytics with FL Chart and Syncfusion Flutter Charts
- **Animations**: Lottie for engaging loading animations

## Architecture

Finmate follows a clean architecture approach with:

- **Models**: Data classes representing entities like User, Transaction, Group, BankAccount
- **Providers**: Riverpod state notifiers for managing application state
- **Services**: Firebase interaction services for authentication, database operations
- **UI**: Screen components organized by feature
- **Widgets**: Reusable UI components

## Project Structure
