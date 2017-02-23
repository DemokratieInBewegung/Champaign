// @flow
import React, { Component } from 'react';
import { FormattedMessage } from 'react-intl';
import _ from 'lodash';
import classnames from 'classnames';
import FieldShape from '../../components/FieldShape/FieldShape';
import type { Country, CountryPhoneCode, Target, FormType, Errors } from '../../containers/CallToolView/CallToolView';
import type { Field } from '../../components/FieldShape/FieldShape';

type OwnProps = {
  targetByCountryEnabled: boolean;
  countries: Country[];
  targets: Target[];
  countriesPhoneCodes: CountryPhoneCode[];
  selectedTarget: Target;
  form: FormType;
  errors: Errors;
  onCountryCodeChange: (string) => void;
  onMemberPhoneNumberChange: (string) => void;
  onMemberPhoneCountryCodeChange: (string) => void;
  onSubmit: (any) => void;
  loading: boolean;
}

const memberPhoneNumberField:Field = {
  data_type: 'phone',
  name: 'call_tool[member_phone_number]',
  label: <FormattedMessage id='call_tool.form.phone_number' />,
  default_value: '',
  required: true,
  disabled: false
};

const memberPhoneCountryCodeField:Field = {
  data_type: 'phone',
  name: 'call_tool[member_phone_number]',
  label: <FormattedMessage id='call_tool.form.phone_country_code' />,
  default_value: '',
  required: true,
  disabled: false
};

const countryCodeField:Field = {
  data_type: 'select',
  name: 'call_tool[country_code]',
  label: <FormattedMessage id='call_tool.form.country' />,
  default_value: null,
  required: true,
  disabled: false,
  choices: []
};

class Form extends Component {
  props: OwnProps;
  fields: { [key: string]: Field };

  constructor(props: OwnProps) {
    super(props);

    this.fields = {
      memberPhoneNumberField: memberPhoneNumberField,
      memberPhoneCountryCodeField: memberPhoneCountryCodeField,
      countryCodeField: { ...countryCodeField, choices: this.countryCodeOptions() }
    };
  }

  countryCodeOptions() {
    return this.props.countries.map((country) => {
      return { value: country.code, label: country.name };
    });
  }

  phoneNumberCountryName() {
    const strippedCountryCode = this.props.form.memberPhoneCountryCode.replace('+', '');
    const countryPhoneCode = _.find(this.props.countriesPhoneCodes, (countryCode) => {
      return countryCode.code === strippedCountryCode;
    });

    return countryPhoneCode ? countryPhoneCode.name : '';
  }

  render() {
    return(
      <form className='action-form form--big' data-remote="true" >
        <FieldShape
        key="countryCode"
        errorMessage={this.props.errors.countryCode}
        onChange={this.props.onCountryCodeChange}
        value={this.props.form.countryCode}
        field={this.fields.countryCodeField}
        className="countryCodeField"
        />

        <FieldShape
        key="memberPhoneCountryCode"
        errorMessage={this.props.errors.memberPhoneCountryCode}
        onChange={this.props.onMemberPhoneCountryCodeChange}
        value={this.props.form.memberPhoneCountryCode}
        field={this.fields.memberPhoneCountryCodeField}
        className="phoneCountryCodeField" />

        <FieldShape
        key="memberPhoneNumber"
        errorMessage={this.props.errors.memberPhoneNumber}
        onChange={this.props.onMemberPhoneNumberChange}
        value={this.props.form.memberPhoneNumber}
        field={this.fields.memberPhoneNumberField}
        className="phoneNumberField" />

        <p className={classnames({'guessed-country-name': true, hidden: !_.isEmpty(this.props.errors.memberPhoneNumber) })}>
          <span>
            { this.phoneNumberCountryName() }
          </span>
        </p>

        <div className="clearfix"> </div>

        <div className="selectedTarget">
          <p>
            { !_.isEmpty(this.props.selectedTarget) &&
              <span>
                <FormattedMessage id="call_tool.you_will_be_calling" />
                &nbsp;
                <span className="selectedTargetName">
                  {this.props.selectedTarget.name}
                </span>
                , {this.props.selectedTarget.title}
              </span>
            }
          </p>
        </div>

        <button
        type="submit"
        onClick={this.props.onSubmit}
        className="button action-form__submit-button"
        disabled={ this.props.loading ? 'disabled' : '' }>
          <FormattedMessage id="call_tool.form.submit" />
        </button>
      </form>
    );
  }
}

export default Form;
