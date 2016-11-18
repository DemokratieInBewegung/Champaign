// @flow
import React, { Component } from 'react';
import { FormattedNumber, FormattedMessage } from 'react-intl';
import DonationBands from '../DonationBands/DonationBands';
import Button from '../Button/Button';

const FORMATTED_NUMBER_DEFAULTS = {
  style: 'currency',
  minimumFractionDigits: 0,
  maximumFractionDigits: 0,
};

type OwnProps = {
  donationAmount: ?number;
  donationBands: number[];
  currency: string;
  currencies: string[];
  nextStepTitle: string;
  selectAmount: (amount: ?number) => void;
  changeCurrency: (currency: string) => void;
  proceed: () => void;
};

type OwnState = {
  customAmount: ?number;
  currencyDropdownVisible: boolean;
  proceedButtonVisible: boolean;
};

export default class AmountSelection extends Component {
  props: OwnProps;
  state: OwnState;

  static title(amount: ?number, currency: string): string {
    if (amount == null) {
      return <FormattedMessage id="amount" defaultMessage="AMOUNT" />;
    }
    return <FormattedNumber {...FORMATTED_NUMBER_DEFAULTS} value={amount} currency={currency} />;

  }

  constructor(props: OwnProps) {
    super(props);

    this.state = {
      customAmount: null,
      proceedButtonVisible: false,
      currencyDropdownVisible: false,
    };
  }


  componentWillMount() {
    console.log('COMPONENT WILL MOUNT');
  }

  selectAmount(amount: ?number) {
    this.props.selectAmount(amount);
  }

  toggleCurrencyDropdown() {
    this.setState({
      currencyDropdownVisible: !this.state.currencyDropdownVisible,
    });
  }

  toggleProceedButton(visible: boolean) {
    this.setState({ proceedButtonVisible: visible });
  }

  onSelectCurrency(currency: string) {
    this.props.changeCurrency(currency);
  }

  render() {
    const { proceedButtonVisible } = this.state;
    return (
      <div className="AmountSelection-container section">
        <DonationBands
          ref="donationBands"
          amounts={this.props.donationBands}
          currency={this.props.currency}
          proceed={this.props.proceed}
          selectAmount={this.selectAmount.bind(this)}
          toggleProceedButton={this.toggleProceedButton.bind(this)}
        />
        <p>
          <FormattedMessage
            id="AmountSelection_currencyInfo"
            defaultMessage="Values are shown in {currency}. {link}."
            values={{
              currency: this.props.currency,
              link: <a href="#" onClick={this.toggleCurrencyDropdown.bind(this)}>
                <FormattedMessage id="change_currency" defaultMessage="Change currency" />
              </a>
            }}
          />
        </p>
        {this.state.currencyDropdownVisible &&
          <select value={this.props.currency} onChange={e => this.onSelectCurrency(e.target.value)}>
            {this.props.currencies.map(c =>
              <option key={c} value={c}>{c}</option>
            )}
          </select>
        }

        { proceedButtonVisible && (
          <Button className="btn" onClick={() => this.props.proceed()} disabled={!this.props.donationAmount}>
            <FormattedMessage
              id="proceed_to_details"
              defaultMessage="Proceed {name}"
              values={{name: this.props.nextStepTitle}}/>
          </Button>
        )}
      </div>
    );
  }
}