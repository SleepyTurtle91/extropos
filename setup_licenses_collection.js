#!/usr/bin/env node
// Setup script for creating the 'licenses' collection in Appwrite
// Run with: node setup_licenses_collection.js

const sdk = require('node-appwrite');

// Initialize the Appwrite SDK
const client = new sdk.Client();
client
    .setEndpoint('https://appwrite.extropos.org/v1') // Your Appwrite endpoint
    .setProject('6940a64500383754a37f') // Your project ID
    .setKey('088ea83f36a48f15cc11adf63392f2da1f98f16aa554fa161baf5b28044bcd94ae3cd5e8c0365b161aadbfecb8e3cfa00e4ef24e46299903586388203272156da954c2b4204971321233701997c5bcda4764d25f774ac54fbfc595524a2900b4e216d35cbea9a1923970a099cc89463880f2b110f8362a7fdd1231f0e628b03f'); // Your API key

const databases = new sdk.Databases(client);

async function setupLicensesCollection() {
    try {
        console.log('Setting up licenses collection...');

        // Create the collection
        const collection = await databases.createCollection(
            'pos_db', // Database ID
            'licenses', // Collection ID
            'licenses', // Collection name
            [
                sdk.Permission.read(sdk.Role.any()), // Allow read for authenticated users
                sdk.Permission.write(sdk.Role.any()), // Allow write for authenticated users
            ]
        );

        console.log('Collection created:', collection.$id);

        // Create attributes
        const attributes = [
            { key: 'license_key', type: 'string', size: 255, required: true },
            { key: 'device_id', type: 'string', size: 255, required: true },
            { key: 'email', type: 'string', size: 255, required: false },
            { key: 'activated_at', type: 'datetime', required: true },
            { key: 'is_active', type: 'boolean', required: true, default: true },
        ];

        for (const attr of attributes) {
            if (attr.type === 'string') {
                await databases.createStringAttribute(
                    'pos_db',
                    'licenses',
                    attr.key,
                    attr.size,
                    attr.required,
                    attr.default || ''
                );
            } else if (attr.type === 'boolean') {
                await databases.createBooleanAttribute(
                    'pos_db',
                    'licenses',
                    attr.key,
                    attr.required,
                    attr.default || false
                );
            } else if (attr.type === 'datetime') {
                await databases.createDatetimeAttribute(
                    'pos_db',
                    'licenses',
                    attr.key,
                    attr.required
                );
            }
            console.log(`Attribute ${attr.key} created`);
        }

        // Create index on license_key for fast lookups
        await databases.createIndex(
            'pos_db',
            'licenses',
            'license_key_index',
            'key', // Index type
            ['license_key'],
            ['ASC']
        );

        console.log('Index created');
        console.log('Licenses collection setup complete!');

    } catch (error) {
        console.error('Error setting up collection:', error);
    }
}

setupLicensesCollection();