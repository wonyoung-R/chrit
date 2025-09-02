require 'httparty'
require 'nokogiri'
require 'base64'

class GithubExtractor
  USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
  GITHUB_API_BASE = 'https://api.github.com'
  
  def extract(url)
    Rails.logger.info "GithubExtractor: Processing #{url}"
    
    # URL 파싱
    parsed = parse_github_url(url)
    
    case parsed[:type]
    when 'repository'
      extract_repository(parsed)
    when 'file'
      extract_file(parsed)
    when 'issue'
      extract_issue(parsed)
    when 'pull_request'
      extract_pull_request(parsed)
    when 'gist'
      extract_gist(parsed)
    else
      # 일반 GitHub 페이지는 웹 스크래핑
      extract_generic(url)
    end
  rescue StandardError => e
    Rails.logger.error "GithubExtractor Error: #{e.message}"
    raise
  end
  
  private
  
  def parse_github_url(url)
    uri = URI.parse(url)
    path_parts = uri.path.split('/').reject(&:empty?)
    
    return { type: 'unknown', url: url } if path_parts.empty?
    
    owner = path_parts[0]
    repo = path_parts[1]
    
    result = { owner: owner, repo: repo, url: url }
    
    # URL 타입 판별
    if path_parts.length == 2
      result[:type] = 'repository'
    elsif path_parts[2] == 'blob' || path_parts[2] == 'tree'
      result[:type] = 'file'
      result[:branch] = path_parts[3]
      result[:path] = path_parts[4..-1]&.join('/')
    elsif path_parts[2] == 'issues' && path_parts[3]
      result[:type] = 'issue'
      result[:number] = path_parts[3].to_i
    elsif path_parts[2] == 'pull' && path_parts[3]
      result[:type] = 'pull_request'
      result[:number] = path_parts[3].to_i
    elsif uri.host == 'gist.github.com'
      result[:type] = 'gist'
      result[:gist_id] = path_parts.last
    else
      result[:type] = 'unknown'
    end
    
    result
  end
  
  def extract_repository(parsed)
    # GitHub API로 리포지토리 정보 가져오기
    api_url = "#{GITHUB_API_BASE}/repos/#{parsed[:owner]}/#{parsed[:repo]}"
    readme_url = "#{api_url}/readme"
    
    repo_data = fetch_github_api(api_url)
    readme_data = fetch_github_readme(readme_url)
    
    title = "#{repo_data['full_name']} - #{repo_data['description']}"
    
    content = build_repository_content(repo_data, readme_data)
    
    {
      title: title,
      content: content,
      image: repo_data['owner']['avatar_url'],
      metadata: {
        url: parsed[:url],
        type: 'github_repository',
        owner: parsed[:owner],
        repo: parsed[:repo],
        stars: repo_data['stargazers_count'],
        forks: repo_data['forks_count'],
        language: repo_data['language'],
        topics: repo_data['topics'],
        created_at: repo_data['created_at'],
        updated_at: repo_data['updated_at'],
        extracted_at: Time.current
      }
    }
  end
  
  def extract_file(parsed)
    # 파일 내용 가져오기
    api_url = "#{GITHUB_API_BASE}/repos/#{parsed[:owner]}/#{parsed[:repo]}/contents/#{parsed[:path]}"
    api_url += "?ref=#{parsed[:branch]}" if parsed[:branch]
    
    file_data = fetch_github_api(api_url)
    
    # 파일 내용 디코딩
    content = if file_data['content']
      Base64.decode64(file_data['content'])
    else
      "File too large to display directly"
    end
    
    # 파일 타입에 따른 처리
    formatted_content = format_file_content(content, parsed[:path])
    
    {
      title: "#{parsed[:path]} - #{parsed[:repo]}",
      content: formatted_content,
      image: nil,
      metadata: {
        url: parsed[:url],
        type: 'github_file',
        owner: parsed[:owner],
        repo: parsed[:repo],
        path: parsed[:path],
        size: file_data['size'],
        sha: file_data['sha'],
        extracted_at: Time.current
      }
    }
  end
  
  def extract_issue(parsed)
    api_url = "#{GITHUB_API_BASE}/repos/#{parsed[:owner]}/#{parsed[:repo]}/issues/#{parsed[:number]}"
    comments_url = "#{api_url}/comments"
    
    issue_data = fetch_github_api(api_url)
    comments_data = fetch_github_api(comments_url)
    
    content = build_issue_content(issue_data, comments_data)
    
    {
      title: "#{issue_data['title']} · Issue ##{parsed[:number]} · #{parsed[:repo]}",
      content: content,
      image: issue_data['user']['avatar_url'],
      metadata: {
        url: parsed[:url],
        type: 'github_issue',
        owner: parsed[:owner],
        repo: parsed[:repo],
        number: parsed[:number],
        state: issue_data['state'],
        labels: issue_data['labels'].map { |l| l['name'] },
        created_at: issue_data['created_at'],
        updated_at: issue_data['updated_at'],
        extracted_at: Time.current
      }
    }
  end
  
  def extract_pull_request(parsed)
    api_url = "#{GITHUB_API_BASE}/repos/#{parsed[:owner]}/#{parsed[:repo]}/pulls/#{parsed[:number]}"
    comments_url = "#{GITHUB_API_BASE}/repos/#{parsed[:owner]}/#{parsed[:repo]}/issues/#{parsed[:number]}/comments"
    
    pr_data = fetch_github_api(api_url)
    comments_data = fetch_github_api(comments_url)
    
    content = build_pr_content(pr_data, comments_data)
    
    {
      title: "#{pr_data['title']} · Pull Request ##{parsed[:number]} · #{parsed[:repo]}",
      content: content,
      image: pr_data['user']['avatar_url'],
      metadata: {
        url: parsed[:url],
        type: 'github_pull_request',
        owner: parsed[:owner],
        repo: parsed[:repo],
        number: parsed[:number],
        state: pr_data['state'],
        merged: pr_data['merged'],
        created_at: pr_data['created_at'],
        updated_at: pr_data['updated_at'],
        extracted_at: Time.current
      }
    }
  end
  
  def extract_gist(parsed)
    api_url = "#{GITHUB_API_BASE}/gists/#{parsed[:gist_id]}"
    
    gist_data = fetch_github_api(api_url)
    
    content = build_gist_content(gist_data)
    
    {
      title: gist_data['description'] || "Gist #{parsed[:gist_id]}",
      content: content,
      image: gist_data['owner']['avatar_url'],
      metadata: {
        url: parsed[:url],
        type: 'github_gist',
        gist_id: parsed[:gist_id],
        files: gist_data['files'].keys,
        public: gist_data['public'],
        created_at: gist_data['created_at'],
        updated_at: gist_data['updated_at'],
        extracted_at: Time.current
      }
    }
  end
  
  def extract_generic(url)
    # 일반 GitHub 페이지 스크래핑
    response = fetch_page(url)
    doc = Nokogiri::HTML(response.body)
    
    title = doc.at('title')&.text&.strip || "GitHub Page"
    
    # 메인 콘텐츠 추출
    content_element = doc.at('.repository-content, .container-lg, main')
    content = content_element ? extract_generic_content(content_element) : ""
    
    {
      title: title,
      content: content,
      image: doc.at('meta[property="og:image"]')&.[]('content'),
      metadata: {
        url: url,
        type: 'github_page',
        description: doc.at('meta[name="description"]')&.[]('content'),
        extracted_at: Time.current
      }
    }
  end
  
  def fetch_github_api(url)
    response = HTTParty.get(url,
      headers: {
        'User-Agent' => USER_AGENT,
        'Accept' => 'application/vnd.github.v3+json',
        'Authorization' => github_token ? "token #{github_token}" : nil
      }.compact
    )
    
    if response.success?
      JSON.parse(response.body)
    else
      Rails.logger.warn "GitHub API request failed: #{response.code}"
      {}
    end
  rescue => e
    Rails.logger.error "GitHub API error: #{e.message}"
    {}
  end
  
  def fetch_github_readme(url)
    response = HTTParty.get(url,
      headers: {
        'User-Agent' => USER_AGENT,
        'Accept' => 'application/vnd.github.v3.raw',
        'Authorization' => github_token ? "token #{github_token}" : nil
      }.compact
    )
    
    response.success? ? response.body : nil
  rescue
    nil
  end
  
  def fetch_page(url)
    HTTParty.get(url,
      headers: {
        'User-Agent' => USER_AGENT,
        'Accept' => 'text/html,application/xhtml+xml'
      },
      follow_redirects: true,
      timeout: 15
    )
  end
  
  def build_repository_content(repo_data, readme_content)
    output = []
    
    # 리포지토리 정보
    output << "# #{repo_data['full_name']}\n"
    output << "#{repo_data['description']}\n" if repo_data['description']
    output << "\n---\n"
    
    # 통계
    output << "## 📊 Statistics\n"
    output << "- ⭐ Stars: #{repo_data['stargazers_count']}"
    output << "- 🍴 Forks: #{repo_data['forks_count']}"
    output << "- 👁️ Watchers: #{repo_data['watchers_count']}"
    output << "- 📝 Issues: #{repo_data['open_issues_count']}"
    output << "- 🔖 License: #{repo_data['license']['name']}" if repo_data['license']
    output << "- 🗣️ Language: #{repo_data['language']}" if repo_data['language']
    output << "\n"
    
    # 토픽
    if repo_data['topics'] && repo_data['topics'].any?
      output << "## 🏷️ Topics\n"
      output << repo_data['topics'].map { |t| "`#{t}`" }.join(' ')
      output << "\n"
    end
    
    # README
    if readme_content
      output << "\n## 📖 README\n"
      output << readme_content
    end
    
    output.join("\n")
  end
  
  def build_issue_content(issue_data, comments_data)
    output = []
    
    # 이슈 헤더
    output << "# #{issue_data['title']}\n"
    output << "_Issue ##{issue_data['number']} · #{issue_data['state']}_\n"
    output << "_Opened by #{issue_data['user']['login']} on #{format_date(issue_data['created_at'])}_\n"
    output << "\n---\n"
    
    # 라벨
    if issue_data['labels'] && issue_data['labels'].any?
      labels = issue_data['labels'].map { |l| "`#{l['name']}`" }.join(' ')
      output << "**Labels:** #{labels}\n\n"
    end
    
    # 이슈 본문
    output << "## Description\n"
    output << issue_data['body'] || "No description provided"
    output << "\n"
    
    # 댓글
    if comments_data && comments_data.any?
      output << "\n## 💬 Comments (#{comments_data.length})\n"
      comments_data.each do |comment|
        output << "\n### #{comment['user']['login']} - #{format_date(comment['created_at'])}\n"
        output << comment['body']
        output << "\n"
      end
    end
    
    output.join("\n")
  end
  
  def build_pr_content(pr_data, comments_data)
    output = []
    
    # PR 헤더
    output << "# #{pr_data['title']}\n"
    output << "_Pull Request ##{pr_data['number']} · #{pr_data['state']}_\n"
    output << "_Opened by #{pr_data['user']['login']} on #{format_date(pr_data['created_at'])}_\n"
    
    if pr_data['merged']
      output << "_✅ Merged on #{format_date(pr_data['merged_at'])}_\n"
    end
    
    output << "\n---\n"
    
    # PR 정보
    output << "## 📊 PR Information\n"
    output << "- **Base:** `#{pr_data['base']['ref']}`\n"
    output << "- **Head:** `#{pr_data['head']['ref']}`\n"
    output << "- **Commits:** #{pr_data['commits']}\n"
    output << "- **Files changed:** #{pr_data['changed_files']}\n"
    output << "- **Additions:** +#{pr_data['additions']}\n"
    output << "- **Deletions:** -#{pr_data['deletions']}\n"
    output << "\n"
    
    # PR 본문
    output << "## Description\n"
    output << pr_data['body'] || "No description provided"
    output << "\n"
    
    # 댓글
    if comments_data && comments_data.any?
      output << "\n## 💬 Comments (#{comments_data.length})\n"
      comments_data.each do |comment|
        output << "\n### #{comment['user']['login']} - #{format_date(comment['created_at'])}\n"
        output << comment['body']
        output << "\n"
      end
    end
    
    output.join("\n")
  end
  
  def build_gist_content(gist_data)
    output = []
    
    # Gist 헤더
    output << "# #{gist_data['description'] || 'Untitled Gist'}\n"
    output << "_Created by #{gist_data['owner']['login']} on #{format_date(gist_data['created_at'])}_\n"
    output << "\n---\n"
    
    # 파일들
    gist_data['files'].each do |filename, file_info|
      output << "\n## 📄 #{filename}\n"
      output << "_#{file_info['language']} · #{file_info['size']} bytes_\n"
      output << "\n```#{file_info['language']&.downcase || 'plaintext'}\n"
      output << file_info['content']
      output << "\n```\n"
    end
    
    output.join("\n")
  end
  
  def format_file_content(content, path)
    extension = File.extname(path).downcase
    language = detect_language(extension)
    
    output = []
    output << "## 📄 #{File.basename(path)}\n"
    output << "\n```#{language}\n"
    output << content
    output << "\n```\n"
    
    output.join
  end
  
  def detect_language(extension)
    languages = {
      '.rb' => 'ruby',
      '.py' => 'python',
      '.js' => 'javascript',
      '.ts' => 'typescript',
      '.jsx' => 'jsx',
      '.tsx' => 'tsx',
      '.java' => 'java',
      '.cpp' => 'cpp',
      '.c' => 'c',
      '.go' => 'go',
      '.rs' => 'rust',
      '.php' => 'php',
      '.swift' => 'swift',
      '.kt' => 'kotlin',
      '.scala' => 'scala',
      '.sh' => 'bash',
      '.sql' => 'sql',
      '.html' => 'html',
      '.css' => 'css',
      '.scss' => 'scss',
      '.json' => 'json',
      '.xml' => 'xml',
      '.yaml' => 'yaml',
      '.yml' => 'yaml',
      '.md' => 'markdown'
    }
    
    languages[extension] || 'plaintext'
  end
  
  def extract_generic_content(element)
    output = []
    
    element.children.each do |child|
      case child.name.downcase
      when 'h1', 'h2', 'h3', 'h4', 'h5', 'h6'
        level = child.name[1].to_i
        prefix = '#' * level
        output << "\n#{prefix} #{child.text.strip}\n"
      when 'p'
        text = child.text.strip
        output << "#{text}\n" unless text.empty?
      when 'pre'
        code = child.at('code') || child
        output << "\n```\n#{code.text}\n```\n"
      when 'ul', 'ol'
        child.css('li').each do |li|
          output << "• #{li.text.strip}\n"
        end
      when 'div', 'section', 'article'
        output << extract_generic_content(child)
      end
    end
    
    output.join("\n").gsub(/\n{3,}/, "\n\n").strip
  end
  
  def format_date(date_string)
    Date.parse(date_string).strftime("%B %d, %Y") rescue date_string
  end
  
  def github_token
    # GitHub 토큰이 설정되어 있으면 사용 (옵션)
    ENV['GITHUB_TOKEN'] || Rails.application.credentials.dig(:github, :token)
  end
end