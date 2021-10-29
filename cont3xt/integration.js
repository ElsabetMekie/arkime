/******************************************************************************/
/* integration.js  -- Integrations wrapper
 *
 * Copyright Yahoo Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this Software except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
'use strict';

const glob = require('glob');
const path = require('path');

class Integration {
  static debug = 0;
  static cache;
  static getConfig;
  static integrations = {
    all: [],
    ip: [],
    domain: [],
    phone: [],
    email: [],
    hash: [],
    url: [],
    text: []
  };

  static initialize (options) {
    Integration.debug = options.debug ?? 0;
    Integration.cache = options.cache;
    Integration.getConfig = options.getConfig;
    options.integrationsPath = options.integrationsPath ?? path.join(__dirname, '/integrations/');

    glob(options.integrationsPath + 'integration.*.js', (err, files) => {
      files.forEach((file) => {
        require(file);
      });
    });
  }

  static register (integration) {
    if (Integration.debug > 0) {
      console.log('REGISTER', integration.name);
    }
    integration.cacheable = integration.cacheable ?? true;

    // cacheTime order we check:
    //   cacheTimeout in integration section
    //   cacheTimeout in cont3xt section
    //   cacheTimeout in integration code
    //   60 minutes
    integration.cacheTimeout = parseInt(integration.getConfig('cacheTimeout', Integration.getConfig('cont3xt', 'cacheTimeout', integration.cacheTimeout ?? 60 * 60 * 1000)));
    console.log('cacheTimeout', integration.name, integration.cacheTimeout);

    if (typeof (integration.itypes) !== 'object') {
      console.log('Missing .itypes object', integration);
      return;
    }

    if (typeof (integration.name) !== 'string') {
      console.log('Missing .name', integration);
      return;
    }

    Integration.integrations.all.push(integration);
    for (const itype in integration.itypes) {
      Integration.integrations[itype].push(integration);
    }
  }

  static classify (str) {
    if (str.match(/^(\d{3})[-. ]?(\d{3})[-. ]?(\d{4})$/)) {
      return 'phone';
    }

    // https://www.oreilly.com/library/view/regular-expressions-cookbook/9780596802837/ch07s16.html
    if (str.match(/^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/)) {
      return 'ip'; // v4
    }

    // modified https://www.oreilly.com/library/view/regular-expressions-cookbook/9781449327453/ch08s17.html
    if (str.match(/^(?:[a-fA-F0-9]{1,4}:){7}[a-fA-F0-9]{1,4}$/)) {
      return 'ip'; // v6
    }

    // https://emailregex.com/
    // eslint-disable-next-line no-useless-escape
    if (str.match(/^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/)) {
      return 'email';
    }

    // https://urlregex.com/
    // eslint-disable-next-line no-useless-escape
    if (str.match(/((([A-Za-z]{3,9}:(?:\/\/)?)(?:[\-;:&=\+\$,\w]+@)?[A-Za-z0-9\.\-]+|(?:www\.|[\-;:&=\+\$,\w]+@)[A-Za-z0-9\.\-]+)((?:\/[\+~%\/\.\w\-_]*)?\??(?:[\-\+=&;%@\.\w_]*)#?(?:[\.\!\/\\\w]*))?)/)) {
      return 'url';
    }

    if (str.match(/^[A-Fa-f0-9]{32}$/) || str.match(/^[A-Fa-f0-9]{40}$/) || str.match(/^[A-Fa-f0-9]{64}$/)) {
      return 'hash';
    }

    // https://www.oreilly.com/library/view/regular-expressions-cookbook/9781449327453/ch08s15.html
    if (str.match(/^([a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,}$/)) {
      return 'domain';
    }

    // Not sure
    return 'text';
  }

  /**
   * List out all the integrations, if we can do them. Maybe card info goes here?
   */
  static async apiList (req, res, next) {
    const results = {};
    const integrations = Integration.integrations.all;
    for (const integration of integrations) {
      let doable = true;
      if (integration.userSettings) {
        for (const setting in integration.userSettings) {
          if (!integration.getUserConfig(req.user, setting)) {
            doable = false;
            break;
          }
        }
      }
      results[integration.name] = {
        doable: doable,
        cacheTimeout: integration.cacheTimeout
      };
    }

    return res.send({ success: true, results: results });
  }

  /**
   * The search api to go against integrations
   */
  static async apiSearch (req, res, next) {
    if (!req.params.query) {
      return res.send({ success: false, text: 'Missing query' });
    }
    const query = req.params.query.trim();
    const skipCache = req.query.skipCache === 'true';

    const itype = Integration.classify(query);

    const integrations = Integration.integrations[itype];
    let sent = 0;
    const total = integrations.length;
    res.write(JSON.stringify({ success: true, itype: itype, sent: sent, total: total, text: 'more to follow' }));
    res.write('\n');

    for (const integration of integrations) {
      const cacheKey = `${integration.name}-${itype}-${query}`;

      if (!skipCache && Integration.cache && integration.cacheable) {
        const response = await Integration.cache.get(cacheKey);
        // TODO - Fix dup sending code for cache and not cache
        if (response && Date.now() - response._createTime < integration.cacheTimeout) {
          sent++;
          res.write(JSON.stringify({ sent: sent, total: total, name: integration.name, data: response }));
          res.write('\n');
          if (sent === total) {
            res.end(JSON.stringify({ finished: true }));
          }
          continue;
        }
      }

      integration[integration.itypes[itype]](req.user, query)
        .then(response => {
          sent++;
          if (response) {
            response._createTime = Date.now();
            res.write(JSON.stringify({ sent: sent, total: total, name: integration.name, data: response }));
            res.write('\n');
            if (response && Integration.cache && integration.cacheable) {
              Integration.cache.set(cacheKey, response);
            }
          }
          if (sent === total) {
            res.end(JSON.stringify({ finished: true }));
          }
        });
    }
  }

  /**
   * Return all the settings and current values that a user can set about
   * Intergrations so a Setting UI can be built on the fly.
   */
  static async apiUserSettings (req, res, next) {
    // ALW: Should this be an array or obj?
    const result = [];
    const integrations = Integration.integrations.all;
    for (const integration of integrations) {
      if (integration.userSettings) {
        const values = {};
        for (const setting in integration.userSettings) {
          const v = req.user.getCont3xtConfig(setting);
          if (v) {
            values[setting] = v;
          }
        }
        result.push({
          name: integration.name,
          settings: integration.userSettings,
          values: values
        });
      }
    }
    res.send({ success: true, settings: result });
  }

  getConfig (k, d) {
    return Integration.getConfig(this.name, k, d);
  }

  /**
   * Return a config value by first check the user, then the section, and then the cont3xt section.
   * If the start of the k matches this.name, it is removed before checking the section.
   */
  getUserConfig (user, k, d) {
    if (user.cont3xt) {
      const v = user.getCont3xtConfig(k);
      if (v !== undefined) { return v; }
    }

    if (k.startsWith(this.name)) {
      const v = Integration.getConfig(this.name, k.substring(this.name.length));
      if (v !== undefined) { return v; }
    } else {
      const v = Integration.getConfig(this.name, k);
      if (v !== undefined) { return v; }
    }

    return Integration.getConfig('cont3xt', k, d);
  }

  userAgent () {
    Integration.getConfig('cont3xt', 'userAgent', 'cont3xt');
  }
}

module.exports = Integration;

// Must be at bottom to avoid circular dependency
// const Db = require('./db.js');
