require 'rugged'
require 'pathname'

class History
  def initialize(archive, dir)
    @archive = archive
    if File.directory? dir
      begin
        repo = Rugged::Repository.discover(dir)

        repo_base = Pathname.new(repo.workdir).realpath.to_s
        real_dir = Pathname.new(dir).realpath.to_s
        raise "confused! #{repo_base} #{real_dir}" unless real_dir.start_with?(repo_base)
        @relative_root = real_dir[repo_base.length+1..-1] || ""
        $stderr.puts "#{real_dir} in #{repo_base} : #{@relative_root}"

        check_repo_clean(repo, @relative_root)
      rescue Rugged::RepositoryError
        repo = Rugged::Repository.init_at(dir)
        @relative_root = ""
      end
    elsif File.exist? dir
      fail "#{dir} exists as file"
    else
      Dir.mkdir(dir)
      repo = Rugged::Repository.init_at(dir)
      @relative_root = ""
    end
    @repo = repo
    @dir_path = dir
  end

  class Entry
    attr_reader :git_fn, :dir_fn, :path
    def initialize(f, root, repository)
      @git_fn = f

      @dir_fn = if root.empty?
                  f
                else
                  f[root.length+1..-1]
                end

      @path = repository.workdir + '/' + @dir_fn
    end
  end

  def entry(from_git)
    Entry.new(from_git, @relative_root, @repo)
  end
  
  def check_repo_clean(repo, sub)
    $stderr.puts "check_repo_clean(#{repo},#{sub})"
    clean = true
    repo.status do |file, data|
      change = classify_file(sub, file)
      clean = false if change == :real
    end
    clean
  end

  def commit_posts
    repo = @repo
    sub = @relative_root

    commits = 0
    todo = {}
    @repo.status do |file, data|
      change = classify_file(sub, file)
      todo[change] ||= []
      todo[change] << file
    end
    if todo[:top]
      todo[:top].each { |file| repo.index.add file }

      author = {:email => 'abelard@example.org', :time => Time.now, :name => 'abelard'}
      parents = []
      parents << repo.head.target unless repo.head_unborn?
      commit = Rugged::Commit.create(repo,
                                     :author => author,
                                     :message => "feed info",
                                     :commitor => author,
                                     :parents => parents,
                                     :tree => repo.index.write_tree(repo),
                                     :update_ref => "HEAD")
      commits = commits+1
    end

    to_commit = @archive.sort_entries(todo[:real].map { |f| entry(f) })
    
    to_commit.each do |entry|
p entry
      file = entry.git_fn
      $stderr.puts "Adding #{file}"

      repo.index.add file
      commit = Rugged::Commit.create(repo,
                                     :author => author,
                                     :message => "post",
                                     :commitor => author,
                                     :parents => [repo.head.target],
                                     :tree => repo.index.write_tree(repo),
                                     :update_ref => "HEAD")
      commits = commits+1
    end

    repo.index.write if commits > 0
  end

  def classify_file(subdir, file)
    # normally 1 archive = 1 repo, but if you have a repo of several
    # archives, ignore file changes outside
    return :outside unless file.start_with?(subdir)

    filename = Pathname.new(file).basename.to_s

    return :real if filename.start_with?("post-") or filename.start_with?("comment-")
    return :top if filename.start_with?("feed") or filename.start_with?("channel")

    return :unknown
  end
end

