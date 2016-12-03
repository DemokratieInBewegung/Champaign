/* @flow */
import React from 'react';
import { render } from 'react-dom';
import { addLocaleData } from 'react-intl';
import enLocaleData from 'react-intl/locale-data/en';
import deLocaleData from 'react-intl/locale-data/de';
import frLocaleData from 'react-intl/locale-data/fr';
import esLocaleData from 'react-intl/locale-data/es';

import configureStore from './state';
import ComponentWrapper from './ComponentWrapper';

import FundraiserView from './containers/FundraiserView/FundraiserView';

import './components.css';

addLocaleData([
  ...enLocaleData,
  ...deLocaleData,
  ...frLocaleData,
  ...esLocaleData,
]);

window.initializeStore = configureStore;

window.mountFundraiser = (root: string, store?: Store, initialState?: any = {})  => {
  if (store) {
    store.dispatch({ type: 'parse_champaign_data', payload: initialState });
  }

  render(
    <ComponentWrapper store={store}>
      <FundraiserView />
    </ComponentWrapper>,
    document.getElementById(root)
  );

  if (process.env.NODE_ENV === 'development' && module.hot) {
    module.hot.accept('./containers/FundraiserView/FundraiserView', () => {
      const UpdatedFundraiserView = require('./containers/FundraiserView/FundraiserView').default;
      render(
        <ComponentWrapper store={store}>
          <UpdatedFundraiserView />
        </ComponentWrapper>,
        document.getElementById(root)
      );
    });
  }
};