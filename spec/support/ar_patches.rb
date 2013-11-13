# Monkey patch to raise exceptions from after_commit
# https://github.com/rails/rails/pull/11123

module ActiveRecord
  module ConnectionAdapters
    module DatabaseStatements
      def within_new_transaction(options = {})
        transaction = begin_transaction(options)
        yield
      rescue Exception => error
        rollback_transaction if transaction
        raise
      ensure
        begin
          commit_transaction unless error
        rescue Exception
          rollback_transaction unless transaction.state.complete?
          raise
        end
      end
    end
  end
end

module ActiveRecord
  module ConnectionAdapters
    # Not patched but need to be here
    class Transaction; end
    class ClosedTransaction < Transaction; end

    class TransactionState
      def complete?
        committed? || rolledback?
      end
    end

    class OpenTransaction < Transaction
      def commit_records
        @state.set_state(:committed)
        records.uniq.each do |record|
          begin
            record.committed!
          rescue => e
            record.logger.error(e) if record.respond_to?(:logger) && record.logger
            raise
          end
        end
      end
    end
  end
end