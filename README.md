# Deposits Exercise


## Requirements

A tradeline on a credit report represents an account, such as a credit card or car loan.

In the codebase, the following exists:

* The `Tradeline` model, which can be used to store tradelines in the database.
* A `Tradeline` controller, which serves both the `index` and `show` routes for tradelines.
* Basic `rspec` tests on the controller with a `tradeline` FactoryBot.

Add in the ability to create deposits for a specific tradeline using a JSON API call. You should store the deposit date (this is most likely a future date), and amount. Expose the outstanding balance for a given tradeline in the JSON output for `TradelinesController#show`, and `TradelinesController#index`. The oustanding balance should be calculated as the `amount` minus all of the deposit amounts.

In addition:

* A deposit should not be able to be created that exceeds the outstanding balance of a tradeline.
* You should return validation errors if a deposit cannot be created.
* Expose endpoints for seeing all deposits for a given tradeline, as well as seeing an individual deposit.

Feel free to add any gems to the `Gemfile`, and touch any of the existing code. For example, if you prefer to use PostgreSQL or MySQL over the included SQLite, or a serializer of your choice, please go ahead. This is not required, but you can be as creative as you want.

This exercise is purely API based, and will not have any frontend components. Please do not spend more than 3 hours on this.

## Setup

The exercise requires Ruby 3.3.0. Simply clone the repo, and run `bundle` to get started. This will install Rails 7.1.2, and the other specified gems.

## Submission

Please do not fork the repo; if forked accidentally, please delete the fork. For review, either of the following methods for submission are preferred:

* Cloning the repository and then uploading it under your Github account for review.
* Zipping up the directory. 
## Implementation Notes

I used Claude Code as a pair programmer for this exercise; I reviewed, tested, and can walk through all of the code.

### Endpoints

| Method | Path | Description |
| --- | --- | --- |
| GET | `/tradelines` | All tradelines, each with `outstanding_balance` |
| GET | `/tradelines/:id` | One tradeline, with `outstanding_balance` |
| GET | `/tradelines/:tradeline_id/deposits` | Deposits for a tradeline, ordered by date |
| GET | `/tradelines/:tradeline_id/deposits/:id` | One deposit |
| POST | `/tradelines/:tradeline_id/deposits` | Create a deposit |

```bash
curl -X POST localhost:3000/tradelines/1/deposits \
  -H 'Content-Type: application/json' \
  -d '{"deposit": {"amount": "150.00", "deposit_date": "2026-12-01"}}'
```

Successful creates return `201`. Validation failures return `422` with `{"errors": {"amount": ["exceeds the outstanding balance of 100.00"]}}`. Unknown records return `404`, and an empty body returns `400`.

### Design decisions

* **Outstanding balance is computed, not stored.** `amount - SUM(deposits.amount)` is always correct and avoids keeping a denormalized column in sync. `GET /tradelines` loads every total in a single grouped query (`Tradeline.with_deposits_total`) to avoid an N+1.
* **The balance check is a model validation**, so it applies no matter how a deposit is created. It excludes the deposit itself, so updates are validated correctly too.
* **Concurrent deposits:** creation runs inside `tradeline.with_lock`, so two simultaneous requests can't both pass the balance check and overdraw it. On PostgreSQL/MySQL this is a `SELECT ... FOR UPDATE` row lock. SQLite ignores `FOR UPDATE` but serializes writes; production would use Postgres.
* **Deposit dates** are required but not forced to be in the future, since backdated deposits may legitimately need to be recorded. An unparseable date gets `is not a valid date` rather than Rails' default `can't be blank`.
* **Amounts must be positive and have at most 2 decimal places.** Rails would otherwise silently round `10.005` to `10.01`; for money it's safer to reject the request than store a different amount than the client sent.
* Money is stored as `decimal(8,2)` and serialized as strings (the Rails default for `BigDecimal`), so JSON clients don't lose precision to floats.

### What I'd do next with more time

* Paginate `GET /tradelines` and the deposits list.
* Add a DB-level `CHECK (amount > 0)` constraint as a backstop for the model validation.
* Move JSON shaping into dedicated serializers (or Jbuilder views) instead of `as_json` on the model, once responses grow beyond a few fields.
* Add authentication/authorization; currently any client can read or create deposits for any tradeline.
* Version the API (`/api/v1/...`) before external clients depend on it.

### Running

```bash
bundle install
bin/rails db:migrate
bundle exec rspec
```
