using Artemis.API.Entities;

namespace Artemis.API.Services.Interfaces;

public interface ICommentService
{
    ValueTask<CommentListViewModel> GetList(CommentFilterViewModel filterViewModel);
    ValueTask<CommentGetViewModel?> GetById(int id);
    ValueTask<ResultViewModel> Create(CreateOrUpdateCommentViewModel viewModel);
    ValueTask<ResultViewModel> Update(CreateOrUpdateCommentViewModel viewModel);
    ValueTask<ResultViewModel> Delete(int id);
}