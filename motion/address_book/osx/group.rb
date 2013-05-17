# Wrapper for iOS ABGroup
#
# * groups are saved to the database immediately upon new()
# * members are added with <<
#
module AddressBook
  class Group
    attr_reader :attributes, :error

    def initialize(opts)
      @address_book = opts[:address_book]
      if opts[:ab_group]
        # import existing
        @ab_group = opts[:ab_group]
        @attributes = nil
      else
        # create new
        @ab_group = nil
        @attributes = opts[:attributes]
      end
    end

    def address_book
      @address_book ||= AddressBook.address_book
    end

    def save
      ABAddressBookAddRecord(address_book, ab_group, error)
      ABAddressBookSave(address_book, error)
      @attributes = nil
      @new_record = false
      self
    end

    def new_record?
      uid == KABRecordInvalidID
    end
    alias :new? :new_record?

    def delete!
      unless new?
        address_book.removeRecord(ab_group)
        address_book.save
        @ab_group = nil
        self
      end
    end

    def ab_group
      @ab_group || convert_dict_to_ab
    end
    alias :ab_record :ab_group

    def get_field(field)
      ab_group.valueForProperty(field)
    end

    def uid
      get_field(KABUIDProperty)
    end

    def name
      get_field(KABGroupNameProperty)
    end

    def size
      members.count
    end

    def members
      people + subgroups
    end
    def people
      ab_group.members.map do |ab_person|
        AddressBook::Person.new({}, ab_person, :address_book => address_book)
      end
    end
    def subgroups
      ab_group.subgroups.map do |subgroup|
        AddressBook::Group.new(:ab_group => subgroup, :address_book => address_book)
      end
    end

    def <<(person_or_group)
      raise ArgumentError, "Must save member before adding to group" if person_or_group.new?
      ABGroupAddMember(ab_group, person_or_group.ab_record, error)
    end

    private

    def convert_dict_to_ab
      @ab_group = ABGroupCreate()

      # groups only have a single regular attribute (name)
      if v = @attributes[:name]
        ABRecordSetValue(@ab_group, KABGroupNameProperty, v, error)
      end

      save

      @ab_group
    end
  end
end
