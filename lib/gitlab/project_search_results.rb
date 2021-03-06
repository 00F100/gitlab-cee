module Gitlab
  class ProjectSearchResults < SearchResults
    attr_reader :project, :repository_ref

    def initialize(current_user, project, query, repository_ref = nil)
      @current_user = current_user
      @project = project
      @repository_ref = if repository_ref.present?
                          repository_ref
                        else
                          nil
                        end
      @query = query
    end

    def objects(scope, page = nil)
      case scope
      when 'notes'
        notes.page(page).per(per_page)
      when 'blobs'
        Kaminari.paginate_array(blobs).page(page).per(per_page)
      when 'wiki_blobs'
        Kaminari.paginate_array(wiki_blobs).page(page).per(per_page)
      when 'commits'
        Kaminari.paginate_array(commits).page(page).per(per_page)
      else
        super
      end
    end

    def blobs_count
      @blobs_count ||= blobs.count
    end

    def notes_count
      @notes_count ||= notes.count
    end

    def wiki_blobs_count
      @wiki_blobs_count ||= wiki_blobs.count
    end

    def commits_count
      @commits_count ||= commits.count
    end

    private

    def blobs
      if project.empty_repo? || query.blank?
        []
      else
        project.repository.search_files(query, repository_ref)
      end
    end

    def wiki_blobs
      if project.wiki_enabled? && query.present?
        project_wiki = ProjectWiki.new(project)

        unless project_wiki.empty?
          project_wiki.search_files(query)
        else
          []
        end
      else
        []
      end
    end

    def notes
      project.notes.user.search(query, as_user: @current_user).order('updated_at DESC')
    end

    def commits
      if project.empty_repo? || query.blank?
        []
      else
        project.repository.find_commits_by_message(query).compact
      end
    end

    def project_ids_relation
      project
    end
  end
end
