// obtain plugin
var cc = initCookieConsent();

// run plugin with your configuration
cc.run({
    current_lang: 'en',
    autoclear_cookies: true,                   // default: false
    theme_css: 'css/cookieconsent.css',  // 🚨 replace with a valid path
    page_scripts: true,                        // default: false

    // mode: 'opt-in'                          // default: 'opt-in'; value: 'opt-in' or 'opt-out'
    // delay: 0,                               // default: 0
    // auto_language: '',                      // default: null; could also be 'browser' or 'document'
    // autorun: true,                          // default: true
    // force_consent: false,                   // default: false
    // hide_from_bots: false,                  // default: false
    // remove_cookie_tables: false             // default: false
    // cookie_name: 'cc_cookie',               // default: 'cc_cookie'
    // cookie_expiration: 182,                 // default: 182 (days)
    // cookie_necessary_only_expiration: 182   // default: disabled
    // cookie_domain: location.hostname,       // default: current domain
    // cookie_path: '/',                       // default: root
    // cookie_same_site: 'Lax',                // default: 'Lax'
    // use_rfc_cookie: false,                  // default: false
    // revision: 0,                            // default: 0

    onFirstAction: function(user_preferences, cookie){
        // callback triggered only once on the first accept/reject action
    },

    onAccept: function (cookie) {
        // callback triggered on the first accept/reject action, and after each page load
    },

    onChange: function (cookie, changed_categories) {
        // callback triggered when user changes preferences after consent has already been given
             // If analytics category is disabled => disable google analytics
       if (!cc.allowedCategory('analytics')) {
           typeof gtag === 'function' && gtag('consent', 'update', {
               'analytics_storage': 'denied'
           });
       }
    },

    gui_options: {
        consent_modal: {
            layout: 'box',               // box/cloud/bar
            position: 'bottom center',     // bottom/middle/top + left/right/center
            transition: 'slide',           // zoom/slide
            swap_buttons: false            // enable to invert buttons
        },
        settings_modal: {
            layout: 'box',                 // box/bar
            // position: 'left',           // left/right
            transition: 'slide'            // zoom/slide
        }
    },

    languages: {
        'en': {
            consent_modal: {
                title: 'We use cookies',
                description: 'Hi, this website uses essential cookies to ensure its proper operation and tracking cookies to understand how you interact with it. The latter will be set only after consent. <button type="button" data-cc="c-settings" class="cc-link">Read in detail</button>',
                primary_btn: {
                    text: 'Accept all',
                    role: 'accept_all'              // 'accept_selected' or 'accept_all'
                },
                secondary_btn: {
                    text: 'Reject all',
                    role: 'accept_necessary'        // 'settings' or 'accept_necessary'
                }
            },
            settings_modal: {
                title: 'Cookie preferences',
                save_settings_btn: 'Save settings',
                accept_all_btn: 'Accept all',
                reject_all_btn: 'Reject all',
                close_btn_label: 'Close',
                cookie_table_headers: [
                    {col1: 'Name'},
                    {col2: 'Domain'},
                    {col3: 'Expiration'},
                    {col4: 'Description'}
                ],
                blocks: [
                    {
                        title: 'Cookie usage',
                        description: 'We use cookies and similar technologies on our website and process personal data about you, such as your IP address. We also share this data with third parties. Data processing may be done with your consent or on the basis of a legitimate interest, which you can object to in the individual privacy settings. You have the right to consent to essential services only and to modify or revoke your consent at a later time in the privacy policy.'
                    }, {
                        title: 'Essential cookies',
                        description: 'Essential services are required for the basic functionality of the website. They only contain technically necessary services. These services cannot be objected to.',
                        toggle: {
                            value: 'necessary',
                            enabled: true,
                            readonly: true          // cookie categories with readonly=true are all treated as "necessary cookies"
                        },
                        cookie_table: [             // list of all expected cookies
                            {
                                col1: 'cc_cookie',       // match all cookies starting with "cc_cookie"
                                col2: '.icinga.com',
                                col3: '6 months',
                                col4: 'Cookie Consent asks website visitors for consent to set cookies and process personal data. Cookies are used to test whether cookies can be set, to store reference to documented consent, to store which services from which service groups the visitor has consented to.',
                                is_regex: true
                            }                                    ]

                    }, {
                        title: 'Performance and Analytics cookies',
                        description: 'Statistics services are needed to collect pseudonymous data about the visitors of the website. The data enables us to understand visitors better and to optimize the website.',
                        toggle: {
                            value: 'analytics',     // your cookie category
                            enabled: false,
                            readonly: false
                        },
                        cookie_table: [             // list of all expected cookies
                            {
                                col1: '^_ga',       // match all cookies starting with "_ga"
                                col2: '.icinga.com',
                                col3: '2 years',
			    col4: 'Google Analytics is a service for creating detailed statistics of user behavior on the website. The cookies are used to differentiate users, store campaign related information for and from the user and to link data from multiple page views. <a class="cc-link" href="https://policies.google.com/privacy" target="_blank">Google Privacy Policy</a>',
                                is_regex: true
                            }                                    ]

                    }, {
                        title: 'More information',
		    description: 'Some services process personal data in the USA. By consenting to the use of these services, you also consent to the processing of your data in the USA in accordance with Art. 49 (1) lit. a GDPR. The USA is considered by the ECJ to be a country with an insufficient level of data protection according to EU standards. In particular, there is a risk that your data will be processed by US authorities for control and monitoring purposes, perhaps without the possibility of a legal recourse.<br /><br />You are under 16 years old? Then you cannot consent to optional services. Ask your parents or legal guardians to agree to these services with you. <br /><br />For any queries in relation to our policy on cookies and your choices, please <a class="cc-link" href="https://icinga.com/contact">contact us</a>',
                    }
                ]
            }
        }
    }
});
