class Dog
    attr_accessor :name, :breed, :id

    def initialize(hash)
        hash.each do |key, value|
            self.send(("#{key}="), value)
        end
        self.id ||= nil
    end

    def self::create_table
        sql = <<-SQL
        CREATE TABLE IF NOT EXISTS dogs (
            id INTEGER PRIMARY KEY,
            name TEXT,
            breed TEXT
        )
        SQL
        DB[:conn].execute(sql)
    end

    def self::drop_table
        sql = "DROP TABLE IF EXISTS dogs"
        DB[:conn].execute(sql)
    end

    def self::new_from_db(row)
        hash = {
            :id => row[0],
            :name => row[1],
            :breed => row[2]
        }
        self.new(hash)
    end

    def self::find_by_name(name)
        sql = "SELECT * FROM dogs WHERE name = ? LIMIT 1"
        DB[:conn].execute(sql, name).map do |row|
            self.new_from_db(row)
        end.first
    end

    def self.find_by_id(id)
        sql = "SELECT * FROM dogs WHERE id = ?"
        DB[:conn].execute(sql, id).map do |row|
            self.new_from_db(row)
        end.first
    end

    def self.find_or_create_by(name:, breed:)
        sql = "SELECT * FROM dogs WHERE name = ? AND breed = ?"
        dog = DB[:conn].execute(sql, name, breed).first

        if dog
            new_dog = self.new_from_db(dog)
        else
            new_dog = self.create({:name => name, :breed => breed})
        end
        new_dog
    end

    def update
        sql = "UPDATE dogs SET name = ?, breed = ? WHERE id = ?"
        DB[:conn].execute(sql, self.name, self.breed, self.id)
    end

    def save
        if self.id
            self.update
        else
            sql = "INSERT INTO dogs (name, breed) VALUES (?,?)"
            DB[:conn].execute(sql, self.name, self.breed)
            @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
        end
        self
    end

    def self.create(hash)
        dog = Dog.new(hash)
        dog.save
        dog
    end


end
